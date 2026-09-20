package com.agentops.console.repo;

import com.agentops.console.domain.Patch;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PatchRepository extends JpaRepository<Patch, UUID> {

    @EntityGraph(attributePaths = "reviewVerdict")
    Optional<Patch> findById(UUID id);

    @EntityGraph(attributePaths = "reviewVerdict")
    List<Patch> findByRunIdOrderByCreatedAtAsc(UUID runId);

    /**
     * Per-run patch statistics for the runs-list table (patch count, reviewed,
     * accepted). One grouped query instead of N+1 per-row lookups.
     */
    @Query("""
            select p.run.id,
                   count(p),
                   count(rv),
                   coalesce(sum(case when rv.decision = com.agentops.console.domain.VerdictDecision.ACCEPTED
                                     then 1 else 0 end), 0)
            from Patch p
            left join p.reviewVerdict rv
            where p.run.id in :runIds
            group by p.run.id
            """)
    List<Object[]> findPatchStatsByRunIds(@Param("runIds") Collection<UUID> runIds);
}
