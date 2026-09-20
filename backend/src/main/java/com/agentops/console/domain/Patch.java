package com.agentops.console.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "patch")
public class Patch {

    @Id
    @Column(name = "id", columnDefinition = "uuid")
    private java.util.UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "run_id", nullable = false)
    private AgentRun run;

    @OneToOne(mappedBy = "patch")
    private ReviewVerdict reviewVerdict;

    @Column(name = "file_path", nullable = false)
    private String filePath;

    @Column(name = "diff_unified", nullable = false)
    private String diffUnified;

    @Column(name = "lines_added", nullable = false)
    private Integer linesAdded;

    @Column(name = "lines_removed", nullable = false)
    private Integer linesRemoved;

    @Column(name = "latency_ms", nullable = false)
    private Integer latencyMs;

    @Column(name = "cost_usd", precision = 10, scale = 6, nullable = false)
    private BigDecimal costUsd;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt;

    protected Patch() {
    }

    public Patch(UUID id, AgentRun run, String filePath, String diffUnified,
                 int linesAdded, int linesRemoved, int latencyMs, BigDecimal costUsd,
                 OffsetDateTime createdAt) {
        this.id = id;
        this.run = run;
        this.filePath = filePath;
        this.diffUnified = diffUnified;
        this.linesAdded = linesAdded;
        this.linesRemoved = linesRemoved;
        this.latencyMs = latencyMs;
        this.costUsd = costUsd;
        this.createdAt = createdAt;
    }

    public void setReviewVerdict(ReviewVerdict reviewVerdict) {
        this.reviewVerdict = reviewVerdict;
    }

    public java.util.UUID getId() {
        return id;
    }

    public AgentRun getRun() {
        return run;
    }

    public ReviewVerdict getReviewVerdict() {
        return reviewVerdict;
    }

    public String getFilePath() {
        return filePath;
    }

    public String getDiffUnified() {
        return diffUnified;
    }

    public Integer getLinesAdded() {
        return linesAdded;
    }

    public Integer getLinesRemoved() {
        return linesRemoved;
    }

    public Integer getLatencyMs() {
        return latencyMs;
    }

    public BigDecimal getCostUsd() {
        return costUsd;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }
}
