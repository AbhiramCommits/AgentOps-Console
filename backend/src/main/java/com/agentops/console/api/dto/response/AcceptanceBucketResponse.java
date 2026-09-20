package com.agentops.console.api.dto.response;

import java.time.OffsetDateTime;
import java.util.UUID;

public record AcceptanceBucketResponse(
        UUID variantId,
        String variantName,
        OffsetDateTime bucketStart,
        long accepted,
        long total,
        double acceptanceRate
) {
}
