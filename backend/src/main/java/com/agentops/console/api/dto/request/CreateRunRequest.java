package com.agentops.console.api.dto.request;

import com.agentops.console.domain.RunStatus;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public record CreateRunRequest(
        @NotBlank @Size(max = 100) String tool,
        @NotBlank @Size(max = 200) String repo,
        @NotBlank @Size(max = 200) String branch,
        @NotBlank @Size(max = 100) String model,
        @NotNull UUID variantId,
        RunStatus status,
        OffsetDateTime startedAt,
        OffsetDateTime finishedAt,
        @Min(0) Integer totalTokens,
        List<@Valid CreatePatchRequest> patches
) {

    public record CreatePatchRequest(
            @NotBlank @Size(max = 500) String filePath,
            @NotBlank String diffUnified,
            @NotNull @Min(0) Integer linesAdded,
            @NotNull @Min(0) Integer linesRemoved,
            @NotNull @Min(0) Integer latencyMs,
            @NotNull @jakarta.validation.constraints.DecimalMin("0")
            @jakarta.validation.constraints.Digits(integer = 4, fraction = 6) BigDecimal costUsd
    ) {
    }
}
