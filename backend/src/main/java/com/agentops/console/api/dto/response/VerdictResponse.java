package com.agentops.console.api.dto.response;

import com.agentops.console.domain.ReviewVerdict;

import java.time.OffsetDateTime;
import java.util.UUID;

public record VerdictResponse(
        UUID id,
        UUID patchId,
        String reviewer,
        String decision,
        String overrideReason,
        OffsetDateTime decidedAt
) {
    public static VerdictResponse from(ReviewVerdict verdict) {
        return new VerdictResponse(
                verdict.getId(),
                verdict.getPatch().getId(),
                verdict.getReviewer(),
                verdict.getDecision().name(),
                verdict.getOverrideReason(),
                verdict.getDecidedAt()
        );
    }
}
