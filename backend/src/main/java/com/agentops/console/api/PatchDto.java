package com.agentops.console.api;

import com.agentops.console.domain.Patch;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record PatchDto(
        UUID id,
        UUID runId,
        String filePath,
        String diffUnified,
        Integer linesAdded,
        Integer linesRemoved,
        Integer latencyMs,
        BigDecimal costUsd,
        OffsetDateTime createdAt,
        VerdictDto verdict
) {
    public static PatchDto from(Patch patch) {
        return new PatchDto(
                patch.getId(),
                patch.getRun().getId(),
                patch.getFilePath(),
                patch.getDiffUnified(),
                patch.getLinesAdded(),
                patch.getLinesRemoved(),
                patch.getLatencyMs(),
                patch.getCostUsd(),
                patch.getCreatedAt(),
                patch.getReviewVerdict() == null ? null : VerdictDto.from(patch.getReviewVerdict())
        );
    }
}
