package com.agentops.console.repo;

import com.agentops.console.api.VariantStats;
import com.agentops.console.domain.ReviewVerdict;
import com.agentops.console.domain.VerdictDecision;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public interface ReviewVerdictRepository extends JpaRepository<ReviewVerdict, UUID> {

    List<ReviewVerdict> findByDecisionOrderByDecidedAtDesc(VerdictDecision decision, Pageable pageable);

    List<ReviewVerdict> findByDecisionAndDecidedAtAfterOrderByDecidedAtDesc(VerdictDecision decision, OffsetDateTime since);

    long countByDecision(VerdictDecision decision);

    @Query("""
            select new com.agentops.console.api.VariantStats(
                v.id,
                v.name,
                coalesce(sum(case when rv.decision = com.agentops.console.domain.VerdictDecision.ACCEPTED then 1 else 0 end), 0),
                count(rv)
            )
            from ReviewVerdict rv
            join rv.patch pa
            join pa.run r
            join r.promptVariant v
            group by v.id, v.name
            order by v.name
            """)
    List<VariantStats> findAcceptanceStatsByVariant();
}
