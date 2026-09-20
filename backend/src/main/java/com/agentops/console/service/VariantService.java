package com.agentops.console.service;

import com.agentops.console.api.dto.request.CreateVariantRequest;
import com.agentops.console.api.dto.response.VariantResponse;
import com.agentops.console.api.error.ConflictException;
import com.agentops.console.domain.PromptVariant;
import com.agentops.console.repo.PromptVariantRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class VariantService {

    private final PromptVariantRepository variantRepository;

    public VariantService(PromptVariantRepository variantRepository) {
        this.variantRepository = variantRepository;
    }

    public List<VariantResponse> list() {
        return variantRepository.findAllByOrderByCreatedAtAsc().stream()
                .map(VariantResponse::from)
                .toList();
    }

    @Transactional
    public VariantResponse create(CreateVariantRequest request) {
        if (variantRepository.existsByName(request.name())) {
            throw new ConflictException("prompt variant name already exists: " + request.name());
        }
        PromptVariant variant = new PromptVariant(
                UUID.randomUUID(),
                request.name(),
                request.template(),
                request.description() == null || request.description().isBlank()
                        ? null : request.description().trim(),
                OffsetDateTime.now());
        return VariantResponse.from(variantRepository.save(variant));
    }
}
