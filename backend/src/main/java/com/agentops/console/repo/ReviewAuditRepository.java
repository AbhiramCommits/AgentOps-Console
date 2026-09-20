package com.agentops.console.repo;

import com.agentops.console.domain.ReviewAudit;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ReviewAuditRepository extends JpaRepository<ReviewAudit, UUID> {

    List<ReviewAudit> findByPatchIdOrderByChangedAtAsc(UUID patchId);
}
