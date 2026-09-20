package com.agentops.console.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "review_audit")
public class ReviewAudit {

    @Id
    @Column(name = "id", columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patch_id", nullable = false)
    private Patch patch;

    @Column(name = "reviewer", nullable = false)
    private String reviewer;

    @Enumerated(EnumType.STRING)
    @Column(name = "decision", nullable = false, length = 16)
    private VerdictDecision decision;

    @Column(name = "override_reason")
    private String overrideReason;

    @Enumerated(EnumType.STRING)
    @Column(name = "action", nullable = false, length = 16)
    private ReviewAction action;

    @Column(name = "changed_at", nullable = false)
    private OffsetDateTime changedAt;

    protected ReviewAudit() {
    }

    public ReviewAudit(UUID id, Patch patch, String reviewer, VerdictDecision decision,
                       String overrideReason, ReviewAction action, OffsetDateTime changedAt) {
        this.id = id;
        this.patch = patch;
        this.reviewer = reviewer;
        this.decision = decision;
        this.overrideReason = overrideReason;
        this.action = action;
        this.changedAt = changedAt;
    }

    public UUID getId() {
        return id;
    }

    public Patch getPatch() {
        return patch;
    }

    public String getReviewer() {
        return reviewer;
    }

    public VerdictDecision getDecision() {
        return decision;
    }

    public String getOverrideReason() {
        return overrideReason;
    }

    public ReviewAction getAction() {
        return action;
    }

    public OffsetDateTime getChangedAt() {
        return changedAt;
    }
}
