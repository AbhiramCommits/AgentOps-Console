package com.agentops.console.repo;

import com.agentops.console.domain.PromptVariant;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface PromptVariantRepository extends JpaRepository<PromptVariant, UUID> {

    List<PromptVariant> findAllByOrderByCreatedAtAsc();

    boolean existsByName(String name);
}
