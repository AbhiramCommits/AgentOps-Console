package com.agentops.console.repo;

import com.agentops.console.domain.ReviewVerdict;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface ReviewVerdictRepository extends JpaRepository<ReviewVerdict, UUID> {

    boolean existsByPatchId(UUID patchId);

    Optional<ReviewVerdict> findByPatchId(UUID patchId);
}
