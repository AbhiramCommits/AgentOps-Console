package com.agentops.console.service;

import com.agentops.console.api.dto.response.PatchResponse;
import com.agentops.console.api.error.NotFoundException;
import com.agentops.console.domain.AgentRun;
import com.agentops.console.domain.Patch;
import com.agentops.console.domain.PromptVariant;
import com.agentops.console.domain.RunStatus;
import com.agentops.console.repo.PatchRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PatchServiceTest {

    @Mock
    private PatchRepository patchRepository;

    @Test
    void getPatchReturnsMappedPatch() {
        UUID patchId = UUID.randomUUID();
        AgentRun run = new AgentRun(
                UUID.randomUUID(), "tool", "repo", "main", "model",
                new PromptVariant(UUID.randomUUID(), "v", "t", null, OffsetDateTime.now()),
                RunStatus.SUCCEEDED, OffsetDateTime.now(), null, BigDecimal.ZERO, 100);
        Patch patch = new Patch(patchId, run, "src/main.go", "diff", 1, 1, 500, new BigDecimal("1.25"),
                OffsetDateTime.now());
        when(patchRepository.findById(patchId)).thenReturn(Optional.of(patch));

        PatchService service = new PatchService(patchRepository);
        PatchResponse response = service.getPatch(patchId);

        assertThat(response.id()).isEqualTo(patchId);
        assertThat(response.filePath()).isEqualTo("src/main.go");
        assertThat(response.verdict()).isNull();
    }

    @Test
    void getPatchWithUnknownIdIsNotFound() {
        UUID patchId = UUID.randomUUID();
        when(patchRepository.findById(patchId)).thenReturn(Optional.empty());

        PatchService service = new PatchService(patchRepository);

        assertThatThrownBy(() -> service.getPatch(patchId))
                .isInstanceOf(NotFoundException.class)
                .hasMessageContaining("patch not found");
    }
}
