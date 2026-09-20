package com.agentops.console.repo;

import com.agentops.console.domain.Patch;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PatchRepository extends JpaRepository<Patch, UUID> {

    @EntityGraph(attributePaths = "reviewVerdict")
    Optional<Patch> findById(UUID id);

    @EntityGraph(attributePaths = "reviewVerdict")
    List<Patch> findByRunIdOrderByCreatedAtAsc(UUID runId);
}
