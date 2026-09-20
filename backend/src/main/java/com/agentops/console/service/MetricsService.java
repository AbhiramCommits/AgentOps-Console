package com.agentops.console.service;

import com.agentops.console.api.dto.response.AcceptanceBucketResponse;
import com.agentops.console.api.dto.response.CostLatencyBucketResponse;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class MetricsService {

    private static final String WINDOW = "90 days";

    /**
     * Acceptance rate per prompt variant per time bucket, computed in the
     * database with date_trunc + GROUP BY (no in-memory aggregation).
     *
     * EXPLAIN (captured with SET enable_seqscan = off to expose the V1 index
     * access paths; at production row counts the planner keeps these paths):
     *
     *   ->  Nested Loop
     *         ->  Hash Join  (p.id = rv.patch_id)
     *               ->  Index Scan using idx_patch_run_id on patch p
     *               ->  Hash
     *                     ->  Bitmap Heap Scan on review_verdict rv
     *                           Recheck Cond: (decided_at >= (now() - '90 days'::interval))
     *                           ->  Bitmap Index Scan on idx_review_verdict_decision_decided_at
     *                                 Index Cond: (decided_at >= (now() - '90 days'::interval))
     *         ->  Index Scan using agent_run_pkey on agent_run r  (id = p.run_id)
     *         ->  Index Scan using prompt_variant_pkey on prompt_variant v  (id = r.prompt_variant_id)
     */
    private static final String ACCEPTANCE_SQL = """
            SELECT v.id,
                   v.name,
                   date_trunc(CAST(:bucket AS text), rv.decided_at) AS bucket_start,
                   count(*)                                            AS total,
                   count(*) FILTER (WHERE rv.decision = 'ACCEPTED')    AS accepted
            FROM review_verdict rv
            JOIN patch p ON p.id = rv.patch_id
            JOIN agent_run r ON r.id = p.run_id
            JOIN prompt_variant v ON v.id = r.prompt_variant_id
            WHERE rv.decided_at >= now() - INTERVAL '%s'
            GROUP BY v.id, v.name, bucket_start
            ORDER BY bucket_start, v.name
            """.formatted(WINDOW);

    /**
     * p50/p95 patch latency and summed cost per prompt variant per time bucket,
     * computed in the database with percentile_cont (ordered-set aggregate)
     * + GROUP BY.
     *
     * EXPLAIN (captured with SET enable_seqscan = off to expose the V1 index
     * access paths):
     *
     *   ->  Hash Join  (r.prompt_variant_id = v.id)
     *         ->  Merge Join  (p.run_id = r.id)
     *               ->  Index Scan using idx_patch_run_id on patch p
     *                     Filter: (created_at >= (now() - '90 days'::interval))
     *               ->  Index Scan using agent_run_pkey on agent_run r
     *         ->  Index Scan using prompt_variant_pkey on prompt_variant v
     */
    private static final String COST_LATENCY_SQL = """
            SELECT v.id,
                   v.name,
                   date_trunc(CAST(:bucket AS text), p.created_at)                AS bucket_start,
                   sum(p.cost_usd)                                                AS total_cost_usd,
                   percentile_cont(0.50) WITHIN GROUP (ORDER BY p.latency_ms)     AS p50_latency_ms,
                   percentile_cont(0.95) WITHIN GROUP (ORDER BY p.latency_ms)     AS p95_latency_ms,
                   count(p.id)                                                    AS patch_count
            FROM patch p
            JOIN agent_run r ON r.id = p.run_id
            JOIN prompt_variant v ON v.id = r.prompt_variant_id
            WHERE p.created_at >= now() - INTERVAL '%s'
            GROUP BY v.id, v.name, bucket_start
            ORDER BY bucket_start, v.name
            """.formatted(WINDOW);

    private final EntityManager entityManager;

    public MetricsService(EntityManager entityManager) {
        this.entityManager = entityManager;
    }

    @Transactional(readOnly = true)
    public List<AcceptanceBucketResponse> acceptance(BucketGranularity bucket) {
        @SuppressWarnings("unchecked")
        List<Object[]> rows = entityManager.createNativeQuery(ACCEPTANCE_SQL)
                .setParameter("bucket", bucket.sqlValue())
                .getResultList();
        return rows.stream()
                .map(row -> {
                    long total = ((Number) row[3]).longValue();
                    long accepted = ((Number) row[4]).longValue();
                    return new AcceptanceBucketResponse(
                            (UUID) row[0],
                            (String) row[1],
                            toOffsetDateTime(row[2]),
                            accepted,
                            total,
                            total == 0 ? 0.0 : (double) accepted / total);
                })
                .toList();
    }

    @Transactional(readOnly = true)
    public List<CostLatencyBucketResponse> costLatency(BucketGranularity bucket) {
        @SuppressWarnings("unchecked")
        List<Object[]> rows = entityManager.createNativeQuery(COST_LATENCY_SQL)
                .setParameter("bucket", bucket.sqlValue())
                .getResultList();
        return rows.stream()
                .map(row -> new CostLatencyBucketResponse(
                        (UUID) row[0],
                        (String) row[1],
                        toOffsetDateTime(row[2]),
                        (BigDecimal) row[3],
                        ((Number) row[4]).doubleValue(),
                        ((Number) row[5]).doubleValue(),
                        ((Number) row[6]).longValue()))
                .toList();
    }

    private static OffsetDateTime toOffsetDateTime(Object value) {
        if (value instanceof OffsetDateTime odt) {
            return odt;
        }
        if (value instanceof java.time.Instant instant) {
            return instant.atOffset(java.time.ZoneOffset.UTC);
        }
        return ((java.sql.Timestamp) value).toInstant().atOffset(java.time.ZoneOffset.UTC);
    }
}
