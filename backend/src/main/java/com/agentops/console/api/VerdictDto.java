package com.agentops.console.api;

import com.agentops.console.domain.ReviewVerdict;

import java.time.OffsetDateTime;
import java.util.UUID;

public record VerdictDto(
        UUID id,
        UUID patchId,
        String reviewer,
        String decision,
        String overrideReason,
        OffsetDateTime decidedAt
) {
    public static VerdictDto from(ReviewVerdict verdict) {
        return new VerdictDto(
                verdict.getId(),
                verdict.getPatch().getId(),
                verdict.getReviewer(),
                verdict.getDecision().name(),
                verdict.getOverrideReason(),
                verdict.getDecidedAt()
        );
    }
}
