package com.agentops.console.service;

import com.agentops.console.api.dto.request.ReviewRequest;
import com.agentops.console.api.dto.response.VerdictResponse;
import com.agentops.console.api.error.BusinessValidationException;
import com.agentops.console.api.error.ConflictException;
import com.agentops.console.api.error.NotFoundException;
import com.agentops.console.domain.Patch;
import com.agentops.console.domain.PromptVariant;
import com.agentops.console.domain.ReviewAction;
import com.agentops.console.domain.ReviewAudit;
import com.agentops.console.domain.ReviewVerdict;
import com.agentops.console.domain.AgentRun;
import com.agentops.console.domain.VerdictDecision;
import com.agentops.console.repo.PatchRepository;
import com.agentops.console.repo.ReviewAuditRepository;
import com.agentops.console.repo.ReviewVerdictRepository;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReviewServiceTest {

    @Mock
    private PatchRepository patchRepository;

    @Mock
    private ReviewVerdictRepository verdictRepository;

    @Mock
    private ReviewAuditRepository auditRepository;

    private SimpleMeterRegistry meterRegistry;

    private ReviewService reviewService;

    private final UUID patchId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        meterRegistry = new SimpleMeterRegistry();
        reviewService = new ReviewService(patchRepository, verdictRepository, auditRepository, meterRegistry);
    }

    private Patch patchWithVerdict(ReviewVerdict verdict) {
        PromptVariant variant = new PromptVariant(
                UUID.randomUUID(), "baseline-v1", "template", null, java.time.OffsetDateTime.now());
        AgentRun run = new AgentRun(
                UUID.randomUUID(), "tool", "repo", "main", "model", variant,
                com.agentops.console.domain.RunStatus.SUCCEEDED, java.time.OffsetDateTime.now(),
                java.time.OffsetDateTime.now().plusMinutes(10), java.math.BigDecimal.ZERO, 100);
        Patch patch = new Patch(patchId, run, "src/main.go", "diff", 1, 1, 500,
                new java.math.BigDecimal("1.00"), java.time.OffsetDateTime.now());
        if (verdict != null) {
            patch.setReviewVerdict(verdict);
        }
        return patch;
    }

    private static ReviewRequest accepted() {
        return new ReviewRequest("alice", VerdictDecision.ACCEPTED, null);
    }

    private static ReviewRequest rejected(String overrideReason) {
        return new ReviewRequest("alice", VerdictDecision.REJECTED, overrideReason);
    }

    @Test
    void createReviewRecordsVerdictAndCreatedAudit() {
        Patch patch = patchWithVerdict(null);
        when(patchRepository.findById(patchId)).thenReturn(Optional.of(patch));
        when(verdictRepository.existsByPatchId(patchId)).thenReturn(false);
        when(verdictRepository.save(any(ReviewVerdict.class))).thenAnswer(invocation -> invocation.getArgument(0));

        VerdictResponse response = reviewService.createReview(patchId, accepted());

        assertThat(response.decision()).isEqualTo("ACCEPTED");
        assertThat(response.reviewer()).isEqualTo("alice");

        ArgumentCaptor<ReviewAudit> auditCaptor = ArgumentCaptor.forClass(ReviewAudit.class);
        verify(auditRepository).save(auditCaptor.capture());
        assertThat(auditCaptor.getValue().getAction()).isEqualTo(ReviewAction.CREATED);
        assertThat(auditCaptor.getValue().getDecision()).isEqualTo(VerdictDecision.ACCEPTED);
        assertThat(patch.getReviewVerdict()).isNotNull();
        assertThat(patch.getReviewVerdict().getDecision()).isEqualTo(VerdictDecision.ACCEPTED);

        assertThat(meterRegistry.counter("agentops_patches_reviewed_total", "decision", "accepted").count())
                .isEqualTo(1);
    }

    @Test
    void createReviewOnAlreadyReviewedPatchConflicts() {
        Patch patch = patchWithVerdict(null);
        when(patchRepository.findById(patchId)).thenReturn(Optional.of(patch));
        when(verdictRepository.existsByPatchId(patchId)).thenReturn(true);

        assertThatThrownBy(() -> reviewService.createReview(patchId, accepted()))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("use PUT to amend it");
        verify(verdictRepository, never()).save(any());
        verify(auditRepository, never()).save(any());
    }

    @Test
    void createReviewOnUnknownPatchIsNotFound() {
        when(patchRepository.findById(patchId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> reviewService.createReview(patchId, accepted()))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void rejectedDecisionWithoutOverrideReasonIsRejected() {
        assertThatThrownBy(() -> reviewService.createReview(patchId, rejected(null)))
                .isInstanceOf(BusinessValidationException.class)
                .hasMessageContaining("overrideReason is required");
        assertThatThrownBy(() -> reviewService.createReview(patchId, rejected("   ")))
                .isInstanceOf(BusinessValidationException.class);
        verify(patchRepository, never()).findById(any());
    }

    @Test
    void amendReviewOverwritesVerdictAndAppendsAmendedAudit() {
        Patch patch = patchWithVerdict(null);
        ReviewVerdict existing = new ReviewVerdict(
                UUID.randomUUID(), patch, "bob", VerdictDecision.ACCEPTED, null, java.time.OffsetDateTime.now());
        when(patchRepository.findById(patchId)).thenReturn(Optional.of(patch));
        when(verdictRepository.findByPatchId(patchId)).thenReturn(Optional.of(existing));

        VerdictResponse response = reviewService.amendReview(patchId, rejected("flaky test"));

        assertThat(response.decision()).isEqualTo("REJECTED");
        assertThat(response.overrideReason()).isEqualTo("flaky test");

        ArgumentCaptor<ReviewAudit> auditCaptor = ArgumentCaptor.forClass(ReviewAudit.class);
        verify(auditRepository).save(auditCaptor.capture());
        assertThat(auditCaptor.getValue().getAction()).isEqualTo(ReviewAction.AMENDED);

        assertThat(meterRegistry.counter("agentops_patches_reviewed_total", "decision", "rejected").count())
                .isEqualTo(1);
    }

    @Test
    void amendReviewWithoutExistingVerdictIsNotFound() {
        Patch patch = patchWithVerdict(null);
        when(patchRepository.findById(patchId)).thenReturn(Optional.of(patch));
        when(verdictRepository.findByPatchId(patchId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> reviewService.amendReview(patchId, rejected("reason")))
                .isInstanceOf(NotFoundException.class)
                .hasMessageContaining("use POST to create one");
        verify(auditRepository, never()).save(any());
    }
}
