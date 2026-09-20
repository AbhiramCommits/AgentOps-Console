package com.agentops.console.repo;

import com.agentops.console.domain.AgentRun;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.Optional;
import java.util.UUID;

public interface AgentRunRepository extends JpaRepository<AgentRun, UUID>, JpaSpecificationExecutor<AgentRun> {

    @EntityGraph(attributePaths = "promptVariant")
    Page<AgentRun> findAll(Specification<AgentRun> spec, Pageable pageable);

    @EntityGraph(attributePaths = "promptVariant")
    Optional<AgentRun> findById(UUID id);
}
