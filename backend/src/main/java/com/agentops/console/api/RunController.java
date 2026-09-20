package com.agentops.console.api;

import com.agentops.console.domain.AgentRun;
import com.agentops.console.domain.RunStatus;
import com.agentops.console.repo.AgentRunRepository;
import com.agentops.console.repo.PatchRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/runs")
public class RunController {

    private final AgentRunRepository runRepository;
    private final PatchRepository patchRepository;

    public RunController(AgentRunRepository runRepository, PatchRepository patchRepository) {
        this.runRepository = runRepository;
        this.patchRepository = patchRepository;
    }

    @GetMapping
    public List<RunSummary> list(
            @RequestParam(required = false) UUID variantId,
            @RequestParam(required = false) RunStatus status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        PageRequest pageable = PageRequest.of(Math.max(0, page), Math.min(500, Math.max(1, size)));
        List<AgentRun> runs;
        if (variantId != null && status != null) {
            runs = runRepository.findByPromptVariantIdAndStatusOrderByStartedAtDesc(variantId, status, pageable);
        } else if (variantId != null) {
            runs = runRepository.findByPromptVariantIdOrderByStartedAtDesc(variantId);
        } else if (status != null) {
            runs = runRepository.findByStatusOrderByStartedAtDesc(status, pageable);
        } else {
            runs = runRepository.findAllByOrderByStartedAtDesc(pageable);
        }
        return runs.stream().map(RunSummary::from).toList();
    }

    @GetMapping("/{id}")
    public RunSummary get(@PathVariable UUID id) {
        return runRepository.findById(id)
                .map(RunSummary::from)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "run not found: " + id));
    }

    @GetMapping("/{id}/patches")
    public List<PatchDto> patches(@PathVariable UUID id) {
        if (!runRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "run not found: " + id);
        }
        return patchRepository.findByRunIdOrderByCreatedAtAsc(id).stream()
                .map(PatchDto::from)
                .toList();
    }
}
