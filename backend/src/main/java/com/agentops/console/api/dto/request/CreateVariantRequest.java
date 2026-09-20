package com.agentops.console.api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateVariantRequest(
        @NotBlank @Size(max = 200) String name,
        @NotBlank String template,
        @Size(max = 1000) String description
) {
}
