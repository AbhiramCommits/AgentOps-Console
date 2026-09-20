package com.agentops.console.service;

import com.agentops.console.api.dto.response.AcceptanceBucketResponse;
import com.agentops.console.api.dto.response.CostLatencyBucketResponse;
import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class MetricsServiceTest {

    @Mock
    private EntityManager entityManager;

    @Mock
    private Query query;

    private MetricsService metricsService;

    private final UUID variantId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        when(entityManager.createNativeQuery(anyString())).thenReturn(query);
        when(query.setParameter(anyString(), anyString())).thenReturn(query);
        metricsService = new MetricsService(entityManager);
    }

    @Test
    void acceptanceComputesRatePerBucket() {
        OffsetDateTime day1 = OffsetDateTime.of(2026, 8, 3, 0, 0, 0, 0, ZoneOffset.UTC);
        OffsetDateTime day2 = OffsetDateTime.of(2026, 8, 4, 0, 0, 0, 0, ZoneOffset.UTC);
        when(query.getResultList()).thenReturn(List.of(
                new Object[]{variantId, "baseline-v1", day1, 4L, 2L},
                new Object[]{variantId, "baseline-v1", day2, 4L, 4L}));

        List<AcceptanceBucketResponse> result = metricsService.acceptance(BucketGranularity.DAY);

        assertThat(result).hasSize(2);
        assertThat(result.get(0).bucketStart()).isEqualTo(day1);
        assertThat(result.get(0).accepted()).isEqualTo(2);
        assertThat(result.get(0).total()).isEqualTo(4);
        assertThat(result.get(0).acceptanceRate()).isEqualTo(0.5);
        assertThat(result.get(1).acceptanceRate()).isEqualTo(1.0);
        verify(query).setParameter("bucket", "day");
    }

    @Test
    void acceptanceWithNoVerdictsHasZeroRateInsteadOfNaN() {
        when(query.getResultList()).thenReturn(java.util.Collections.singletonList(
                new Object[]{variantId, "baseline-v1", Instant.parse("2026-08-03T00:00:00Z"), 0L, 0L}));

        List<AcceptanceBucketResponse> result = metricsService.acceptance(BucketGranularity.WEEK);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).acceptanceRate()).isZero();
        assertThat(result.get(0).bucketStart()).isEqualTo(Instant.parse("2026-08-03T00:00:00Z").atOffset(ZoneOffset.UTC));
    }

    @Test
    void costLatencyMapsPercentilesAndCosts() {
        Timestamp bucket = Timestamp.from(Instant.parse("2026-08-03T00:00:00Z"));
        when(query.getResultList()).thenReturn(java.util.Collections.singletonList(
                new Object[]{variantId, "baseline-v1", bucket, new BigDecimal("12.50"), 2500.0, 3850.0, 4L}));

        List<CostLatencyBucketResponse> result = metricsService.costLatency(BucketGranularity.DAY);

        assertThat(result).hasSize(1);
        CostLatencyBucketResponse row = result.get(0);
        assertThat(row.bucketStart().toInstant()).isEqualTo(bucket.toInstant());
        assertThat(row.totalCostUsd()).isEqualByComparingTo("12.50");
        assertThat(row.p50LatencyMs()).isEqualTo(2500.0);
        assertThat(row.p95LatencyMs()).isEqualTo(3850.0);
        assertThat(row.patchCount()).isEqualTo(4);
    }
}
