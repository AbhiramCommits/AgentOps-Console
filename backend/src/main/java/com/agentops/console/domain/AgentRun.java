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

import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity
@Table(name = "agent_run")
public class AgentRun {

    @Id
    @Column(name = "id", columnDefinition = "uuid")
    private java.util.UUID id;

    @Column(name = "tool", nullable = false)
    private String tool;

    @Column(name = "repo", nullable = false)
    private String repo;

    @Column(name = "branch", nullable = false)
    private String branch;

    @Column(name = "model", nullable = false)
    private String model;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "prompt_variant_id", nullable = false)
    private PromptVariant promptVariant;

    @Column(name = "started_at", nullable = false)
    private OffsetDateTime startedAt;

    @Column(name = "finished_at")
    private OffsetDateTime finishedAt;

    @Column(name = "total_cost_usd", precision = 10, scale = 6)
    private BigDecimal totalCostUsd;

    @Column(name = "total_tokens")
    private Integer totalTokens;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 16)
    private RunStatus status;

    protected AgentRun() {
    }

    public java.util.UUID getId() {
        return id;
    }

    public String getTool() {
        return tool;
    }

    public String getRepo() {
        return repo;
    }

    public String getBranch() {
        return branch;
    }

    public String getModel() {
        return model;
    }

    public PromptVariant getPromptVariant() {
        return promptVariant;
    }

    public OffsetDateTime getStartedAt() {
        return startedAt;
    }

    public OffsetDateTime getFinishedAt() {
        return finishedAt;
    }

    public BigDecimal getTotalCostUsd() {
        return totalCostUsd;
    }

    public Integer getTotalTokens() {
        return totalTokens;
    }

    public RunStatus getStatus() {
        return status;
    }
}
