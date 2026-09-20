package com.agentops.console.repo;

import com.agentops.console.domain.AgentRun;
import com.agentops.console.domain.RunStatus;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface AgentRunRepository extends JpaRepository<AgentRun, UUID> {

    @EntityGraph(attributePaths = "promptVariant")
    List<AgentRun> findAllByOrderByStartedAtDesc(Pageable pageable);

    @EntityGraph(attributePaths = "promptVariant")
    List<AgentRun> findByPromptVariantIdOrderByStartedAtDesc(UUID variantId);

    @EntityGraph(attributePaths = "promptVariant")
    List<AgentRun> findByStatusOrderByStartedAtDesc(RunStatus status, Pageable pageable);

    @EntityGraph(attributePaths = "promptVariant")
    List<AgentRun> findByPromptVariantIdAndStatusOrderByStartedAtDesc(UUID variantId, RunStatus status, Pageable pageable);

    long countByStatus(RunStatus status);
}
