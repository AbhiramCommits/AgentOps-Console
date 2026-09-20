package com.agentops.console.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "prompt_variant")
public class PromptVariant {

    @Id
    @Column(name = "id", columnDefinition = "uuid")
    private java.util.UUID id;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "template", nullable = false)
    private String template;

    @Column(name = "description")
    private String description;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt;

    protected PromptVariant() {
    }

    public PromptVariant(UUID id, String name, String template, String description,
                         OffsetDateTime createdAt) {
        this.id = id;
        this.name = name;
        this.template = template;
        this.description = description;
        this.createdAt = createdAt;
    }

    public java.util.UUID getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getTemplate() {
        return template;
    }

    public String getDescription() {
        return description;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }
}
