package com.agentops.console.service;

import com.agentops.console.api.dto.request.CreateRunRequest;
import com.agentops.console.api.dto.response.PageResponse;
import com.agentops.console.api.dto.response.RunDetailResponse;
import com.agentops.console.api.dto.response.RunSummaryResponse;
import com.agentops.console.api.error.NotFoundException;
import com.agentops.console.domain.AgentRun;
import com.agentops.console.domain.Patch;
import com.agentops.console.domain.PromptVariant;
import com.agentops.console.domain.RunStatus;
import com.agentops.console.repo.AgentRunRepository;
import com.agentops.console.repo.PatchRepository;
import com.agentops.console.repo.PromptVariantRepository;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class RunService {

    private final AgentRunRepository runRepository;
    private final PatchRepository patchRepository;
    private final PromptVariantRepository variantRepository;
    private final MeterRegistry meterRegistry;
    private final TransactionTemplate transactionTemplate;

    public RunService(AgentRunRepository runRepository,
                      PatchRepository patchRepository,
                      PromptVariantRepository variantRepository,
                      MeterRegistry meterRegistry,
                      PlatformTransactionManager transactionManager) {
        this.runRepository = runRepository;
        this.patchRepository = patchRepository;
        this.variantRepository = variantRepository;
        this.meterRegistry = meterRegistry;
        this.transactionTemplate = new TransactionTemplate(transactionManager);
    }

    public PageResponse<RunSummaryResponse> list(UUID variantId, RunStatus status,
                                                 OffsetDateTime from, OffsetDateTime to,
                                                 int page, int size) {
        Specification<AgentRun> spec = Specification.where(null);
        if (variantId != null) {
            spec = spec.and((root, query, cb) ->
                    cb.equal(root.get("promptVariant").get("id"), variantId));
        }
        if (status != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("status"), status));
        }
        if (from != null) {
            spec = spec.and((root, query, cb) ->
                    cb.greaterThanOrEqualTo(root.get("startedAt"), from));
        }
        if (to != null) {
            spec = spec.and((root, query, cb) ->
                    cb.lessThanOrEqualTo(root.get("startedAt"), to));
        }
        Pageable pageable = PageRequest.of(Math.max(0, page), Math.min(200, Math.max(1, size)),
                Sort.by(Sort.Direction.DESC, "startedAt"));
        Page<AgentRun> result = runRepository.findAll(spec, pageable);
        Map<UUID, RunSummaryResponse.RunPatchStats> stats = patchStats(result.getContent());
        return PageResponse.from(result,
                run -> RunSummaryResponse.from(run, stats.getOrDefault(run.getId(), RunSummaryResponse.RunPatchStats.ZERO)));
    }

    private Map<UUID, RunSummaryResponse.RunPatchStats> patchStats(List<AgentRun> runs) {
        if (runs.isEmpty()) {
            return Map.of();
        }
        List<UUID> ids = runs.stream().map(AgentRun::getId).toList();
        Map<UUID, RunSummaryResponse.RunPatchStats> stats = new HashMap<>();
        for (Object[] row : patchRepository.findPatchStatsByRunIds(ids)) {
            stats.put((UUID) row[0], new RunSummaryResponse.RunPatchStats(
                    ((Number) row[1]).intValue(),
                    ((Number) row[2]).intValue(),
                    ((Number) row[3]).intValue()));
        }
        return stats;
    }

    public RunDetailResponse getDetail(UUID id) {
        AgentRun run = runRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("run not found: " + id));
        List<Patch> patches = patchRepository.findByRunIdOrderByCreatedAtAsc(id);
        return RunDetailResponse.of(run, patches);
    }

    /**
     * Ingests a run and all of its patches atomically; the whole operation
     * (run + patches) either commits together or not at all.
     */
    public RunDetailResponse ingest(CreateRunRequest request) {
        return meterRegistry.timer("agentops_run_ingest_seconds")
                .record(() -> transactionTemplate.execute(status -> doIngest(request)));
    }

    private RunDetailResponse doIngest(CreateRunRequest request) {
        PromptVariant variant = variantRepository.findById(request.variantId())
                .orElseThrow(() -> new NotFoundException("prompt variant not found: " + request.variantId()));

        List<CreateRunRequest.CreatePatchRequest> patchRequests =
                request.patches() == null ? List.of() : request.patches();

        BigDecimal totalCost = patchRequests.stream()
                .map(CreateRunRequest.CreatePatchRequest::costUsd)
                .reduce(BigDecimal.ZERO, BigDecimal::add)
                .setScale(6, RoundingMode.HALF_UP);

        RunStatus status = request.status() == null ? RunStatus.RUNNING : request.status();
        OffsetDateTime startedAt = request.startedAt() == null ? OffsetDateTime.now() : request.startedAt();
        OffsetDateTime finishedAt = request.finishedAt();
        if (finishedAt == null && status != RunStatus.RUNNING) {
            finishedAt = OffsetDateTime.now();
        }

        AgentRun run = new AgentRun(
                UUID.randomUUID(),
                request.tool(),
                request.repo(),
                request.branch(),
                request.model(),
                variant,
                status,
                startedAt,
                finishedAt,
                totalCost,
                request.totalTokens());
        run = runRepository.save(run);

        List<Patch> patches = new ArrayList<>(patchRequests.size());
        OffsetDateTime patchCreatedAt = OffsetDateTime.now();
        for (CreateRunRequest.CreatePatchRequest patchRequest : patchRequests) {
            patches.add(patchRepository.save(new Patch(
                    UUID.randomUUID(),
                    run,
                    patchRequest.filePath(),
                    patchRequest.diffUnified(),
                    patchRequest.linesAdded(),
                    patchRequest.linesRemoved(),
                    patchRequest.latencyMs(),
                    patchRequest.costUsd(),
                    patchCreatedAt)));
        }
        return RunDetailResponse.of(run, patches);
    }
}
