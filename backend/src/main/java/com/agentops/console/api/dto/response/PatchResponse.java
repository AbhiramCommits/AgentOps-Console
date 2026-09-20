package com.agentops.console.api.dto.response;

import com.agentops.console.domain.Patch;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record PatchResponse(
        UUID id,
        UUID runId,
        String filePath,
        String diffUnified,
        Integer linesAdded,
        Integer linesRemoved,
        Integer latencyMs,
        BigDecimal costUsd,
        OffsetDateTime createdAt,
        VerdictResponse verdict
) {
    public static PatchResponse from(Patch patch) {
        return new PatchResponse(
                patch.getId(),
                patch.getRun().getId(),
                patch.getFilePath(),
                patch.getDiffUnified(),
                patch.getLinesAdded(),
                patch.getLinesRemoved(),
                patch.getLatencyMs(),
                patch.getCostUsd(),
                patch.getCreatedAt(),
                patch.getReviewVerdict() == null ? null : VerdictResponse.from(patch.getReviewVerdict())
        );
    }
}
