package com.agentops.console;

import com.agentops.console.api.dto.response.AcceptanceBucketResponse;
import com.agentops.console.api.dto.response.CostLatencyBucketResponse;
import com.agentops.console.service.BucketGranularity;
import com.agentops.console.service.MetricsService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.jdbc.core.JdbcTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Runs the real Flyway migrations against a Testcontainers Postgres (including
 * the seed data) and verifies the metrics SQL against a month of controlled
 * fixture data with known timestamps, latencies and costs.
 */
@SpringBootTest
@Testcontainers
class MetricsIntegrationTest {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16");

    private static final UUID VARIANT_ID = UUID.fromString("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
    private static final UUID RUN_1 = UUID.fromString("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
    private static final UUID RUN_2 = UUID.fromString("cccccccc-cccc-cccc-cccc-cccccccccccc");
    private static final UUID P1 = UUID.fromString("dddddddd-dddd-dddd-dddd-ddddddddddd1");
    private static final UUID P2 = UUID.fromString("dddddddd-dddd-dddd-dddd-ddddddddddd2");
    private static final UUID P3 = UUID.fromString("dddddddd-dddd-dddd-dddd-ddddddddddd3");
    private static final UUID P4 = UUID.fromString("dddddddd-dddd-dddd-dddd-ddddddddddd4");

    @Autowired
    private JdbcTemplate jdbc;

    @Autowired
    private MetricsService metricsService;

    private static OffsetDateTime utc(int day, int hour) {
        return OffsetDateTime.of(2026, 8, day, hour, 0, 0, 0, ZoneOffset.UTC);
    }

    @BeforeEach
    void insertFixture() {
        jdbc.update("DELETE FROM agent_run WHERE id IN (?, ?)", RUN_1, RUN_2);
        jdbc.update("DELETE FROM prompt_variant WHERE id = ?", VARIANT_ID);
        jdbc.update("""
                INSERT INTO prompt_variant (id, name, template, description, created_at)
                VALUES (?, 'metrics-fixture', 't', 'integration fixture', ?)
                """, VARIANT_ID, utc(1, 0));
        jdbc.update("""
                INSERT INTO agent_run (id, tool, repo, branch, model, prompt_variant_id,
                                       started_at, finished_at, total_cost_usd, total_tokens, status)
                VALUES (?, 'fixture-tool', 'fixture/repo', 'main', 'fixture-model', ?,
                        ?, ?, 10.000000, 1000, 'SUCCEEDED')
                """, RUN_1, VARIANT_ID, utc(1, 9), utc(31, 9));
        jdbc.update("""
                INSERT INTO agent_run (id, tool, repo, branch, model, prompt_variant_id,
                                       started_at, finished_at, total_cost_usd, total_tokens, status)
                VALUES (?, 'fixture-tool', 'fixture/repo', 'main', 'fixture-model', ?,
                        ?, ?, 10.000000, 1000, 'SUCCEEDED')
                """, RUN_2, VARIANT_ID, utc(1, 9), utc(31, 9));

        insertPatch(P1, RUN_1, utc(3, 10), 1000, "1.00");
        insertPatch(P2, RUN_1, utc(3, 11), 2000, "2.00");
        insertPatch(P3, RUN_2, utc(7, 10), 3000, "3.00");
        insertPatch(P4, RUN_2, utc(7, 11), 4000, "4.00");

        insertVerdict(P1, "ACCEPTED", utc(3, 12));
        insertVerdict(P2, "REJECTED", utc(10, 12));
        insertVerdict(P3, "ACCEPTED", utc(24, 12));
        insertVerdict(P4, "ACCEPTED", utc(31, 12));
    }

    private void insertPatch(UUID id, UUID runId, OffsetDateTime createdAt, int latencyMs, String cost) {
        jdbc.update("""
                INSERT INTO patch (id, run_id, file_path, diff_unified, lines_added, lines_removed,
                                   latency_ms, cost_usd, created_at)
                VALUES (?, ?, 'fixture.go', 'diff', 1, 1, ?, ?, ?)
                """, id, runId, latencyMs, new BigDecimal(cost), createdAt);
    }

    private void insertVerdict(UUID patchId, String decision, OffsetDateTime decidedAt) {
        jdbc.update("""
                INSERT INTO review_verdict (id, patch_id, reviewer, decision, override_reason, decided_at)
                VALUES (gen_random_uuid(), ?, 'fixture-reviewer', ?, NULL, ?)
                """, patchId, decision, decidedAt);
    }

    private List<AcceptanceBucketResponse> fixtureAcceptance(BucketGranularity bucket) {
        return metricsService.acceptance(bucket).stream()
                .filter(row -> row.variantId().equals(VARIANT_ID))
                .toList();
    }

    private List<CostLatencyBucketResponse> fixtureCostLatency(BucketGranularity bucket) {
        return metricsService.costLatency(bucket).stream()
                .filter(row -> row.variantId().equals(VARIANT_ID))
                .toList();
    }

    @Test
    void acceptanceDayBucketsAreCorrect() {
        List<AcceptanceBucketResponse> rows = fixtureAcceptance(BucketGranularity.DAY);
        assertThat(rows).hasSize(4);

        assertThat(rows.get(0).bucketStart()).isEqualTo(utc(3, 0));
        assertThat(rows.get(0).accepted()).isEqualTo(1);
        assertThat(rows.get(0).total()).isEqualTo(1);
        assertThat(rows.get(0).acceptanceRate()).isEqualTo(1.0);

        assertThat(rows.get(1).bucketStart()).isEqualTo(utc(10, 0));
        assertThat(rows.get(1).accepted()).isZero();
        assertThat(rows.get(1).total()).isEqualTo(1);
        assertThat(rows.get(1).acceptanceRate()).isZero();

        assertThat(rows.get(2).bucketStart()).isEqualTo(utc(24, 0));
        assertThat(rows.get(3).bucketStart()).isEqualTo(utc(31, 0));
        assertThat(rows.get(3).accepted()).isEqualTo(1);
    }

    @Test
    void acceptanceWeekBucketsStartOnMonday() {
        List<AcceptanceBucketResponse> rows = fixtureAcceptance(BucketGranularity.WEEK);
        // Verdicts fall into the weeks starting 2026-08-03, 08-10, 08-24 and 08-31
        // (all Mondays); the empty week of 08-17 produces no bucket.
        assertThat(rows).hasSize(4);
        assertThat(rows.get(0).bucketStart()).isEqualTo(utc(3, 0));
        assertThat(rows.get(1).bucketStart()).isEqualTo(utc(10, 0));
        assertThat(rows.get(2).bucketStart()).isEqualTo(utc(24, 0));
        assertThat(rows.get(3).bucketStart()).isEqualTo(utc(31, 0));
        assertThat(rows.stream().mapToLong(AcceptanceBucketResponse::total).sum()).isEqualTo(4);
    }

    @Test
    void costLatencyPercentilesAreCorrect() {
        List<CostLatencyBucketResponse> rows = fixtureCostLatency(BucketGranularity.DAY);
        // Patches on Aug 3 (1000, 2000) and Aug 7 (3000, 4000).
        assertThat(rows).hasSize(2);

        // p50 of [1000, 2000] = 1500; p95 = 1000 + 0.95 * 1000 = 1950.
        assertThat(rows.get(0).bucketStart()).isEqualTo(utc(3, 0));
        assertThat(rows.get(0).p50LatencyMs()).isEqualTo(1500.0);
        assertThat(rows.get(0).p95LatencyMs()).isEqualTo(1950.0);
        assertThat(rows.get(0).totalCostUsd()).isEqualByComparingTo("3.00");
        assertThat(rows.get(0).patchCount()).isEqualTo(2);

        // p50 of [3000, 4000] = 3500; p95 = 3000 + 0.95 * 1000 = 3950.
        assertThat(rows.get(1).bucketStart()).isEqualTo(utc(7, 0));
        assertThat(rows.get(1).p50LatencyMs()).isEqualTo(3500.0);
        assertThat(rows.get(1).p95LatencyMs()).isEqualTo(3950.0);
        assertThat(rows.get(1).totalCostUsd()).isEqualByComparingTo("7.00");
    }

    @Test
    void costLatencyWeekBucketAggregatesAllPatches() {
        List<CostLatencyBucketResponse> rows = fixtureCostLatency(BucketGranularity.WEEK);
        // Both days fall inside the week starting 2026-08-03 (a Monday), so one
        // bucket holds all four patches: p50 of [1000..4000] = 2500, p95 = 3850.
        assertThat(rows).hasSize(1);
        CostLatencyBucketResponse bucket = rows.get(0);
        assertThat(bucket.bucketStart()).isEqualTo(utc(3, 0));
        assertThat(bucket.patchCount()).isEqualTo(4);
        assertThat(bucket.p50LatencyMs()).isEqualTo(2500.0);
        assertThat(bucket.p95LatencyMs()).isEqualTo(3850.0);
        assertThat(bucket.totalCostUsd()).isEqualByComparingTo("10.00");
    }

    @Test
    void seedDataIsStillPresent() {
        assertThat(jdbc.queryForObject("SELECT count(*) FROM agent_run", Integer.class))
                .isGreaterThanOrEqualTo(40);
    }
}
