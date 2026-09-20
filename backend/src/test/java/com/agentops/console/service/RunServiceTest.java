package com.agentops.console.service;

import com.agentops.console.api.dto.request.CreateRunRequest;
import com.agentops.console.api.dto.response.RunDetailResponse;
import com.agentops.console.api.error.NotFoundException;
import com.agentops.console.domain.AgentRun;
import com.agentops.console.domain.PromptVariant;
import com.agentops.console.domain.RunStatus;
import com.agentops.console.repo.AgentRunRepository;
import com.agentops.console.repo.PatchRepository;
import com.agentops.console.repo.PromptVariantRepository;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.transaction.support.TransactionTemplate;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RunServiceTest {

    @Mock
    private AgentRunRepository runRepository;

    @Mock
    private PatchRepository patchRepository;

    @Mock
    private PromptVariantRepository variantRepository;

    @Mock
    private org.springframework.transaction.PlatformTransactionManager transactionManager;

    private RunService runService;

    private final UUID variantId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        // Run the ingest lambda synchronously inside a fake transaction so the
        // service logic is exercised with mocked repositories.
        org.mockito.Mockito.lenient().when(transactionManager.getTransaction(any()))
                .thenReturn(mock(org.springframework.transaction.TransactionStatus.class));
        runService = new RunService(runRepository, patchRepository, variantRepository,
                new SimpleMeterRegistry(), transactionManager);
    }

    private static PromptVariant variant() {
        PromptVariant variant = mock(PromptVariant.class);
        when(variant.getId()).thenReturn(UUID.randomUUID());
        when(variant.getName()).thenReturn("baseline-v1");
        return variant;
    }

    private static CreateRunRequest.CreatePatchRequest patchRequest() {
        return new CreateRunRequest.CreatePatchRequest(
                "src/main.go", "diff", 1, 1, 1000, new BigDecimal("2.500000"));
    }

    @Test
    void ingestWithNullPatchesDefaultsToRunningRunWithZeroCost() {
        PromptVariant variant = variant();
        when(variantRepository.findById(variantId)).thenReturn(Optional.of(variant));
        when(runRepository.save(any(AgentRun.class))).thenAnswer(invocation -> invocation.getArgument(0));

        CreateRunRequest request = new CreateRunRequest(
                "agentops-codex", "acme/webapp", "main", "gpt-4o", variantId, null, null, null, null, null);

        RunDetailResponse response = runService.ingest(request);

        assertThat(response.run().status()).isEqualTo("RUNNING");
        assertThat(response.run().finishedAt()).isNull();
        assertThat(response.run().totalCostUsd()).isEqualByComparingTo("0.000000");
        assertThat(response.patches()).isEmpty();

        ArgumentCaptor<AgentRun> runCaptor = ArgumentCaptor.forClass(AgentRun.class);
        verify(runRepository).save(runCaptor.capture());
        assertThat(runCaptor.getValue().getStatus()).isEqualTo(RunStatus.RUNNING);
        assertThat(runCaptor.getValue().getPromptVariant()).isSameAs(variant);
    }

    @Test
    void ingestWithFinishedStatusDefaultsFinishedAtToNow() {
        PromptVariant variant = variant();
        when(variantRepository.findById(variantId)).thenReturn(Optional.of(variant));
        when(runRepository.save(any(AgentRun.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(patchRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        CreateRunRequest request = new CreateRunRequest(
                "agentops-codex", "acme/webapp", "main", "gpt-4o", variantId,
                RunStatus.SUCCEEDED, OffsetDateTime.now().minusHours(1), null, 500,
                List.of(patchRequest()));

        RunDetailResponse response = runService.ingest(request);

        assertThat(response.run().status()).isEqualTo("SUCCEEDED");
        assertThat(response.run().finishedAt()).isNotNull();
        assertThat(response.run().totalCostUsd()).isEqualByComparingTo("2.500000");
        assertThat(response.patches()).hasSize(1);
    }

    @Test
    void ingestWithUnknownVariantIsNotFound() {
        when(variantRepository.findById(variantId)).thenReturn(Optional.empty());

        CreateRunRequest request = new CreateRunRequest(
                "tool", "repo", "branch", "model", variantId, null, null, null, null, null);

        assertThatThrownBy(() -> runService.ingest(request))
                .isInstanceOf(NotFoundException.class)
                .hasMessageContaining("prompt variant not found");
        verify(runRepository, org.mockito.Mockito.never()).save(any());
    }

    @Test
    void getDetailWithUnknownRunIsNotFound() {
        UUID runId = UUID.randomUUID();
        when(runRepository.findById(runId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> runService.getDetail(runId))
                .isInstanceOf(NotFoundException.class);
    }
}
