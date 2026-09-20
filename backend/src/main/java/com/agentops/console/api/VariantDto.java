package com.agentops.console.api;

import com.agentops.console.domain.PromptVariant;

import java.time.OffsetDateTime;
import java.util.UUID;

public record VariantDto(
        UUID id,
        String name,
        String description,
        OffsetDateTime createdAt
) {
    public static VariantDto from(PromptVariant variant) {
        return new VariantDto(
                variant.getId(),
                variant.getName(),
                variant.getDescription(),
                variant.getCreatedAt()
        );
    }
}
