package com.agentops.console.api;

import com.agentops.console.domain.AgentRun;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record RunSummary(
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
        Integer totalTokens
) {
    public static RunSummary from(AgentRun run) {
        return new RunSummary(
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
                run.getTotalTokens()
        );
    }
}
