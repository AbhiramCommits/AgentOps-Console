package com.agentops.console.api;

import com.agentops.console.domain.AgentRun;
import com.agentops.console.domain.RunStatus;
import com.agentops.console.domain.VerdictDecision;
import com.agentops.console.repo.AgentRunRepository;
import com.agentops.console.repo.ReviewVerdictRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

    private final AgentRunRepository runRepository;
    private final ReviewVerdictRepository verdictRepository;

    public DashboardController(AgentRunRepository runRepository, ReviewVerdictRepository verdictRepository) {
        this.runRepository = runRepository;
        this.verdictRepository = verdictRepository;
    }

    @GetMapping("/summary")
    public Summary summary() {
        List<AgentRun> recent = runRepository.findAllByOrderByStartedAtDesc(
                org.springframework.data.domain.PageRequest.of(0, 500));
        long running = runRepository.countByStatus(RunStatus.RUNNING);
        long succeeded = runRepository.countByStatus(RunStatus.SUCCEEDED);
        long failed = runRepository.countByStatus(RunStatus.FAILED);
        long accepted = verdictRepository.countByDecision(VerdictDecision.ACCEPTED);
        long rejected = verdictRepository.countByDecision(VerdictDecision.REJECTED);
        BigDecimal totalCost = recent.stream()
                .map(AgentRun::getTotalCostUsd)
                .filter(java.util.Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        long totalTokens = recent.stream()
                .map(AgentRun::getTotalTokens)
                .filter(java.util.Objects::nonNull)
                .mapToLong(Integer::longValue)
                .sum();
        OffsetDateTime since = OffsetDateTime.now().minusDays(14);
        long accepted14d = verdictRepository
                .findByDecisionAndDecidedAtAfterOrderByDecidedAtDesc(VerdictDecision.ACCEPTED, since).size();
        long rejected14d = verdictRepository
                .findByDecisionAndDecidedAtAfterOrderByDecidedAtDesc(VerdictDecision.REJECTED, since).size();
        return new Summary(running, succeeded, failed, totalCost, totalTokens,
                accepted, rejected, accepted14d, rejected14d);
    }

    public record Summary(
            long runningRuns,
            long succeededRuns,
            long failedRuns,
            BigDecimal totalCostUsd,
            long totalTokens,
            long acceptedVerdicts,
            long rejectedVerdicts,
            long acceptedLast14Days,
            long rejectedLast14Days
    ) {
    }
}
