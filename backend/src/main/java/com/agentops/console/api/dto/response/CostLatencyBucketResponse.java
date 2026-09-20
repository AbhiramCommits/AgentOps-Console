package com.agentops.console.api.dto.response;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record CostLatencyBucketResponse(
        UUID variantId,
        String variantName,
        OffsetDateTime bucketStart,
        BigDecimal totalCostUsd,
        double p50LatencyMs,
        double p95LatencyMs,
        long patchCount
) {
}
