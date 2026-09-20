package com.agentops.console.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;

import java.time.OffsetDateTime;

@Entity
@Table(name = "review_verdict")
public class ReviewVerdict {

    @Id
    @Column(name = "id", columnDefinition = "uuid")
    private java.util.UUID id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patch_id", nullable = false, unique = true)
    private Patch patch;

    @Column(name = "reviewer", nullable = false)
    private String reviewer;

    @Enumerated(EnumType.STRING)
    @Column(name = "decision", nullable = false, length = 16)
    private VerdictDecision decision;

    @Column(name = "override_reason")
    private String overrideReason;

    @Column(name = "decided_at", nullable = false)
    private OffsetDateTime decidedAt;

    protected ReviewVerdict() {
    }

    public java.util.UUID getId() {
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

    public OffsetDateTime getDecidedAt() {
        return decidedAt;
    }
}
