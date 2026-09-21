package com.agentops.console;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.MeterRegistry;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class ApiIntegrationTest {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16");

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private MeterRegistry meterRegistry;

    @Autowired
    private JdbcTemplate jdbc;

    // ------------------------------------------------------------------ helpers

    private Map<String, Object> runPayload(String variantId, Map<String, Object>... patches) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("tool", "agentops-codex");
        payload.put("repo", "acme/webapp");
        payload.put("branch", "main");
        payload.put("model", "gpt-4o");
        payload.put("variantId", variantId);
        payload.put("status", "SUCCEEDED");
        payload.put("startedAt", "2026-09-20T08:00:00Z");
        payload.put("finishedAt", "2026-09-20T08:20:00Z");
        payload.put("totalTokens", 12000);
        payload.put("patches", patches.length == 0 ? null : List.of(patches));
        return payload;
    }

    private Map<String, Object> patchPayload(String filePath, String cost) {
        Map<String, Object> patch = new LinkedHashMap<>();
        patch.put("filePath", filePath);
        patch.put("diffUnified", "diff --git a/" + filePath + " b/" + filePath + "\n@@ -1,1 +1,1 @@\n-old\n+new\n");
        patch.put("linesAdded", 1);
        patch.put("linesRemoved", 1);
        patch.put("latencyMs", 5000);
        patch.put("costUsd", cost);
        return patch;
    }

    private String seedVariantId() throws Exception {
        String body = mockMvc.perform(get("/api/variants"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return objectMapper.readTree(body).get(0).get("id").asText();
    }

    private String ingestRunWithOnePatch() throws Exception {
        String variantId = seedVariantId();
        String body = mockMvc.perform(post("/api/runs")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(
                                runPayload(variantId, patchPayload("src/main.go", "1.234567")))))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return objectMapper.readTree(body).get("run").get("id").asText();
    }

    private String firstPatchIdOf(String runId) throws Exception {
        String body = mockMvc.perform(get("/api/runs/" + runId))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return objectMapper.readTree(body).get("patches").get(0).get("id").asText();
    }

    // ------------------------------------------------------------------ runs

    @Test
    void listRunsIsPaginatedSortedAndFilterable() throws Exception {
        mockMvc.perform(get("/api/runs").param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.page").value(0))
                .andExpect(jsonPath("$.size").value(10))
                .andExpect(jsonPath("$.totalElements").value(org.hamcrest.Matchers.greaterThanOrEqualTo(40)))
                .andExpect(jsonPath("$.items.length()").value(10))
                .andExpect(jsonPath("$.items[0].patchCount").value(org.hamcrest.Matchers.greaterThanOrEqualTo(1)))
                .andExpect(jsonPath("$.items[0].reviewedPatches").isNumber())
                .andExpect(jsonPath("$.items[0].acceptedPatches").isNumber());

        String body = mockMvc.perform(get("/api/runs").param("size", "50"))
                .andReturn().getResponse().getContentAsString();
        var items = objectMapper.readTree(body).get("items");
        OffsetDateTime previous = null;
        for (var item : items) {
            OffsetDateTime started = OffsetDateTime.parse(item.get("startedAt").asText());
            if (previous != null) {
                assertThat(started).isBeforeOrEqualTo(previous);
            }
            previous = started;
        }

        mockMvc.perform(get("/api/runs").param("status", "FAILED").param("size", "50"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[*].status").value(
                        org.hamcrest.Matchers.everyItem(org.hamcrest.Matchers.is("FAILED"))));

        mockMvc.perform(get("/api/runs").param("from", "2099-01-01T00:00:00Z"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(0));

        mockMvc.perform(get("/api/runs").param("to", "2020-01-01T00:00:00Z"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(0));

        String variantId = seedVariantId();
        mockMvc.perform(get("/api/runs").param("variantId", variantId).param("size", "50"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[*].variantId").value(
                        org.hamcrest.Matchers.everyItem(org.hamcrest.Matchers.is(variantId))));
    }

    @Test
    void ingestRunCreatesRunAndPatchesInOneTransaction() throws Exception {
        String variantId = seedVariantId();
        String response = mockMvc.perform(post("/api/runs")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(runPayload(
                                variantId,
                                patchPayload("src/main.go", "1.000000"),
                                patchPayload("src/util.go", "0.500000")))))
                .andExpect(status().isCreated())
                .andExpect(header().exists("Location"))
                .andExpect(jsonPath("$.run.status").value("SUCCEEDED"))
                .andExpect(jsonPath("$.run.totalCostUsd").value(1.5))
                .andExpect(jsonPath("$.run.patchCount").value(2))
                .andExpect(jsonPath("$.run.reviewedPatches").value(0))
                .andExpect(jsonPath("$.run.acceptedPatches").value(0))
                .andExpect(jsonPath("$.patches.length()").value(2))
                .andReturn().getResponse().getContentAsString();

        String runId = objectMapper.readTree(response).get("run").get("id").asText();

        mockMvc.perform(get("/api/runs/" + runId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.patches.length()").value(2))
                .andExpect(jsonPath("$.patches[0].verdict").value(org.hamcrest.Matchers.nullValue()))
                .andExpect(jsonPath("$.run.variantId").value(variantId));

        assertThat(meterRegistry.timer("agentops_run_ingest_seconds").count()).isGreaterThanOrEqualTo(1);
    }

    @Test
    void ingestRunWithUnknownVariantReturnsProblemDetail404() throws Exception {
        mockMvc.perform(post("/api/runs")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(runPayload(UUID.randomUUID().toString()))))
                .andExpect(status().isNotFound())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.title").value("Resource not found"))
                .andExpect(jsonPath("$.instance").value("/api/runs"));
    }

    @Test
    void ingestRunWithBlankToolReturnsValidationProblemDetail() throws Exception {
        Map<String, Object> payload = runPayload(seedVariantId());
        payload.put("tool", "");
        mockMvc.perform(post("/api/runs")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.title").value("Validation failed"))
                .andExpect(jsonPath("$.errors.tool").exists());
    }

    // ------------------------------------------------------------------ patches & reviews

    @Test
    void reviewLifecycleCreatesConflictsAndAmendsWithAuditTrail() throws Exception {
        String runId = ingestRunWithOnePatch();
        String patchId = firstPatchIdOf(runId);

        mockMvc.perform(post("/api/patches/" + patchId + "/review")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reviewer": "alice", "decision": "ACCEPTED"}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.decision").value("ACCEPTED"))
                .andExpect(jsonPath("$.reviewer").value("alice"));

        mockMvc.perform(post("/api/patches/" + patchId + "/review")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reviewer": "bob", "decision": "REJECTED", "overrideReason": "nope"}
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.title").value("State conflict"));

        mockMvc.perform(put("/api/patches/" + patchId + "/review")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reviewer": "diana", "decision": "REJECTED", "overrideReason": "causes a flaky test"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.decision").value("REJECTED"))
                .andExpect(jsonPath("$.reviewer").value("diana"));

        mockMvc.perform(get("/api/patches/" + patchId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.verdict.decision").value("REJECTED"))
                .andExpect(jsonPath("$.verdict.overrideReason").value("causes a flaky test"));

        List<Map<String, Object>> audit = jdbc.queryForList(
                "SELECT action, reviewer, decision FROM review_audit WHERE patch_id = ?::uuid ORDER BY changed_at",
                patchId);
        assertThat(audit).hasSize(2);
        assertThat(audit.get(0)).containsEntry("action", "CREATED").containsEntry("decision", "ACCEPTED");
        assertThat(audit.get(1)).containsEntry("action", "AMENDED").containsEntry("decision", "REJECTED");

        assertThat(meterRegistry.counter("agentops_patches_reviewed_total", "decision", "accepted").count())
                .isGreaterThanOrEqualTo(1);
        assertThat(meterRegistry.counter("agentops_patches_reviewed_total", "decision", "rejected").count())
                .isGreaterThanOrEqualTo(1);
    }

    @Test
    void rejectedReviewWithoutOverrideReasonReturns400() throws Exception {
        String runId = ingestRunWithOnePatch();
        String patchId = firstPatchIdOf(runId);

        mockMvc.perform(post("/api/patches/" + patchId + "/review")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reviewer": "alice", "decision": "REJECTED", "overrideReason": "   "}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Business rule violation"));
    }

    @Test
    void reviewOfUnknownPatchReturns404() throws Exception {
        mockMvc.perform(post("/api/patches/" + UUID.randomUUID() + "/review")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reviewer": "alice", "decision": "ACCEPTED"}
                                """))
                .andExpect(status().isNotFound());
    }

    // ------------------------------------------------------------------ variants

    @Test
    void variantsListAndCreate() throws Exception {
        mockMvc.perform(get("/api/variants"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(8))
                .andExpect(jsonPath("$[0].name").value("baseline-v1"));

        mockMvc.perform(post("/api/variants")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name": "experiment-v9", "template": "You are helpful.", "description": "new"}
                                """))
                .andExpect(status().isCreated())
                .andExpect(header().exists("Location"))
                .andExpect(jsonPath("$.name").value("experiment-v9"));

        mockMvc.perform(post("/api/variants")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name": "experiment-v9", "template": "duplicate"}
                                """))
                .andExpect(status().isConflict());

        mockMvc.perform(post("/api/variants")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name": "", "template": "x"}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.name").exists());
    }

    // ------------------------------------------------------------------ openapi

    @Test
    void openApiDocsAreServed() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.info.title").exists())
                .andExpect(jsonPath("$.paths['/api/runs']").exists());
    }

    // ------------------------------------------------------------------ metrics

    @Test
    void acceptanceMetricsAreBucketedPerVariant() throws Exception {
        mockMvc.perform(get("/api/metrics/acceptance"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(org.hamcrest.Matchers.greaterThan(0)))
                .andExpect(jsonPath("$[0].bucketStart").exists())
                .andExpect(jsonPath("$[0].variantName").exists())
                .andExpect(jsonPath("$[0].accepted").isNumber())
                .andExpect(jsonPath("$[0].total").isNumber())
                .andExpect(jsonPath("$[0].acceptanceRate").isNumber());

        mockMvc.perform(get("/api/metrics/acceptance").param("bucket", "week"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(org.hamcrest.Matchers.greaterThan(0)));

        mockMvc.perform(get("/api/metrics/acceptance").param("bucket", "month"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void costLatencyMetricsHavePercentilesPerVariant() throws Exception {
        mockMvc.perform(get("/api/metrics/cost-latency").param("bucket", "day"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(org.hamcrest.Matchers.greaterThan(0)))
                .andExpect(jsonPath("$[0].p50LatencyMs").isNumber())
                .andExpect(jsonPath("$[0].p95LatencyMs").isNumber())
                .andExpect(jsonPath("$[0].totalCostUsd").isNumber())
                .andExpect(jsonPath("$[0].patchCount").isNumber());

        String body = mockMvc.perform(get("/api/metrics/cost-latency").param("bucket", "week"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        var first = objectMapper.readTree(body).get(0);
        assertThat(first.get("p95LatencyMs").decimalValue())
                .isGreaterThanOrEqualTo(first.get("p50LatencyMs").decimalValue());
    }
}
