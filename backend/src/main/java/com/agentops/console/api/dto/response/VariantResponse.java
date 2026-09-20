package com.agentops.console.api.dto.response;

import com.agentops.console.domain.PromptVariant;

import java.time.OffsetDateTime;
import java.util.UUID;

public record VariantResponse(
        UUID id,
        String name,
        String description,
        String template,
        OffsetDateTime createdAt
) {
    public static VariantResponse from(PromptVariant variant) {
        return new VariantResponse(
                variant.getId(),
                variant.getName(),
                variant.getDescription(),
                variant.getTemplate(),
                variant.getCreatedAt()
        );
    }
}
