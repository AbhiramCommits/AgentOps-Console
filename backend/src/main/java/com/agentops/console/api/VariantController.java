package com.agentops.console.api;

import com.agentops.console.repo.PromptVariantRepository;
import com.agentops.console.repo.ReviewVerdictRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/variants")
public class VariantController {

    private final PromptVariantRepository variantRepository;
    private final ReviewVerdictRepository verdictRepository;

    public VariantController(PromptVariantRepository variantRepository, ReviewVerdictRepository verdictRepository) {
        this.variantRepository = variantRepository;
        this.verdictRepository = verdictRepository;
    }

    @GetMapping
    public List<VariantWithStats> list() {
        Map<UUID, VariantStats> statsByVariant = verdictRepository.findAcceptanceStatsByVariant().stream()
                .collect(Collectors.toMap(VariantStats::variantId, Function.identity()));
        return variantRepository.findAllByOrderByCreatedAtAsc().stream()
                .map(v -> new VariantWithStats(VariantDto.from(v), statsByVariant.get(v.getId())))
                .toList();
    }

    public record VariantWithStats(VariantDto variant, VariantStats stats) {
    }
}
