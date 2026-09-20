package com.agentops.console.api.dto.response;

import com.agentops.console.domain.AgentRun;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record RunSummaryResponse(
        UUID id,
        String tool,
        String repo,
        String branch,
        String model,
        String status,
        UUID variantId,
        String variantName,
        OffsetDateTime startedAt,
        OffsetDateTime finishedAt,
        BigDecimal totalCostUsd,
        Integer totalTokens,
        int patchCount,
        int reviewedPatches,
        int acceptedPatches
) {
    public static RunSummaryResponse from(AgentRun run, RunPatchStats stats) {
        return new RunSummaryResponse(
                run.getId(),
                run.getTool(),
                run.getRepo(),
                run.getBranch(),
                run.getModel(),
                run.getStatus().name(),
                run.getPromptVariant().getId(),
                run.getPromptVariant().getName(),
                run.getStartedAt(),
                run.getFinishedAt(),
                run.getTotalCostUsd(),
                run.getTotalTokens(),
                stats.patchCount(),
                stats.reviewedPatches(),
                stats.acceptedPatches()
        );
    }

    public record RunPatchStats(int patchCount, int reviewedPatches, int acceptedPatches) {

        public static final RunPatchStats ZERO = new RunPatchStats(0, 0, 0);
    }
}
