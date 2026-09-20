package com.agentops.console.api.dto.request;

import com.agentops.console.domain.VerdictDecision;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record ReviewRequest(
        @NotBlank @Size(max = 100) String reviewer,
        @NotNull VerdictDecision decision,
        @Size(max = 1000) String overrideReason
) {
}
