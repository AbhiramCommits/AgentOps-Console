package com.agentops.console.api;

import java.util.UUID;

public record VariantStats(
        UUID variantId,
        String variantName,
        long accepted,
        long totalVerdicts
) {
    public double acceptanceRate() {
        return totalVerdicts == 0 ? 0.0 : (double) accepted / totalVerdicts;
    }
}
