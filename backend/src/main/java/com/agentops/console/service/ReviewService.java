package com.agentops.console.service;

import com.agentops.console.api.dto.request.ReviewRequest;
import com.agentops.console.api.dto.response.VerdictResponse;
import com.agentops.console.api.error.BusinessValidationException;
import com.agentops.console.api.error.ConflictException;
import com.agentops.console.api.error.NotFoundException;
import com.agentops.console.domain.Patch;
import com.agentops.console.domain.ReviewAction;
import com.agentops.console.domain.ReviewAudit;
import com.agentops.console.domain.ReviewVerdict;
import com.agentops.console.domain.VerdictDecision;
import com.agentops.console.repo.PatchRepository;
import com.agentops.console.repo.ReviewAuditRepository;
import com.agentops.console.repo.ReviewVerdictRepository;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.UUID;

@Service
public class ReviewService {

    private final PatchRepository patchRepository;
    private final ReviewVerdictRepository verdictRepository;
    private final ReviewAuditRepository auditRepository;
    private final MeterRegistry meterRegistry;

    public ReviewService(PatchRepository patchRepository,
                         ReviewVerdictRepository verdictRepository,
                         ReviewAuditRepository auditRepository,
                         MeterRegistry meterRegistry) {
        this.patchRepository = patchRepository;
        this.verdictRepository = verdictRepository;
        this.auditRepository = auditRepository;
        this.meterRegistry = meterRegistry;
    }

    /**
     * Records the first review verdict for a patch. A patch can only be
     * reviewed once via POST; later changes must go through {@link #amendReview}.
     */
    @Transactional
    public VerdictResponse createReview(UUID patchId, ReviewRequest request) {
        validate(request);
        Patch patch = patchRepository.findById(patchId)
                .orElseThrow(() -> new NotFoundException("patch not found: " + patchId));
        if (verdictRepository.existsByPatchId(patchId)) {
            throw new ConflictException(
                    "patch " + patchId + " already has a review verdict; use PUT to amend it");
        }
        String overrideReason = blankToNull(request.overrideReason());
        OffsetDateTime now = OffsetDateTime.now();

        ReviewVerdict verdict = new ReviewVerdict(
                UUID.randomUUID(), patch, request.reviewer(), request.decision(),
                overrideReason, now);
        verdict = verdictRepository.save(verdict);
        patch.setReviewVerdict(verdict);
        auditRepository.save(new ReviewAudit(
                UUID.randomUUID(), patch, request.reviewer(), request.decision(),
                overrideReason, ReviewAction.CREATED, now));

        countReview(request.decision());
        return VerdictResponse.from(verdict);
    }

    /**
     * Amends an existing review verdict. The current state in review_verdict
     * is overwritten, but the previous state is preserved in review_audit.
     */
    @Transactional
    public VerdictResponse amendReview(UUID patchId, ReviewRequest request) {
        validate(request);
        Patch patch = patchRepository.findById(patchId)
                .orElseThrow(() -> new NotFoundException("patch not found: " + patchId));
        ReviewVerdict verdict = verdictRepository.findByPatchId(patchId)
                .orElseThrow(() -> new NotFoundException(
                        "no review verdict exists for patch " + patchId + "; use POST to create one"));
        String overrideReason = blankToNull(request.overrideReason());
        OffsetDateTime now = OffsetDateTime.now();

        verdict.amend(request.reviewer(), request.decision(), overrideReason, now);
        auditRepository.save(new ReviewAudit(
                UUID.randomUUID(), patch, request.reviewer(), request.decision(),
                overrideReason, ReviewAction.AMENDED, now));

        countReview(request.decision());
        return VerdictResponse.from(verdict);
    }

    private void validate(ReviewRequest request) {
        if (request.decision() == VerdictDecision.REJECTED && blankToNull(request.overrideReason()) == null) {
            throw new BusinessValidationException(
                    "overrideReason is required when decision is REJECTED");
        }
    }

    private void countReview(VerdictDecision decision) {
        meterRegistry.counter("agentops_patches_reviewed_total",
                        "decision", decision.name().toLowerCase())
                .increment();
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
