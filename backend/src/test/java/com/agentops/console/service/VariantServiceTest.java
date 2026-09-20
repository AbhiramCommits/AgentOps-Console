package com.agentops.console.service;

import com.agentops.console.api.dto.request.CreateVariantRequest;
import com.agentops.console.api.dto.response.VariantResponse;
import com.agentops.console.api.error.ConflictException;
import com.agentops.console.domain.PromptVariant;
import com.agentops.console.repo.PromptVariantRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VariantServiceTest {

    @Mock
    private PromptVariantRepository variantRepository;

    @Test
    void listMapsAllVariants() {
        PromptVariant variant = new PromptVariant(
                UUID.randomUUID(), "baseline-v1", "You are helpful.", "desc", OffsetDateTime.now());
        when(variantRepository.findAllByOrderByCreatedAtAsc()).thenReturn(List.of(variant));

        VariantService service = new VariantService(variantRepository);
        List<VariantResponse> result = service.list();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).name()).isEqualTo("baseline-v1");
    }

    @Test
    void createPersistsNewVariant() {
        when(variantRepository.existsByName("experiment-v9")).thenReturn(false);
        when(variantRepository.save(any(PromptVariant.class))).thenAnswer(invocation -> invocation.getArgument(0));

        VariantService service = new VariantService(variantRepository);
        VariantResponse created = service.create(
                new CreateVariantRequest("experiment-v9", "You are helpful.", "desc"));

        assertThat(created.name()).isEqualTo("experiment-v9");
        assertThat(created.id()).isNotNull();
    }

    @Test
    void createWithDuplicateNameConflicts() {
        when(variantRepository.existsByName("baseline-v1")).thenReturn(true);

        VariantService service = new VariantService(variantRepository);

        assertThatThrownBy(() -> service.create(
                new CreateVariantRequest("baseline-v1", "template", null)))
                .isInstanceOf(ConflictException.class);
        verify(variantRepository, never()).save(any());
    }
}
