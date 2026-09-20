package com.agentops.console.api;

import com.agentops.console.api.dto.request.CreateRunRequest;
import com.agentops.console.api.dto.response.PageResponse;
import com.agentops.console.api.dto.response.RunDetailResponse;
import com.agentops.console.api.dto.response.RunSummaryResponse;
import com.agentops.console.domain.RunStatus;
import com.agentops.console.service.RunService;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;
import java.time.OffsetDateTime;
import java.util.UUID;

@RestController
@RequestMapping("/api/runs")
public class RunController {

    private final RunService runService;

    public RunController(RunService runService) {
        this.runService = runService;
    }

    @GetMapping
    public PageResponse<RunSummaryResponse> list(
            @RequestParam(required = false) UUID variantId,
            @RequestParam(required = false) RunStatus status,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return runService.list(variantId, status, from, to, page, size);
    }

    @GetMapping("/{id}")
    public RunDetailResponse get(@PathVariable UUID id) {
        return runService.getDetail(id);
    }

    @PostMapping
    public ResponseEntity<RunDetailResponse> ingest(@Valid @RequestBody CreateRunRequest request) {
        RunDetailResponse created = runService.ingest(request);
        return ResponseEntity
                .created(URI.create("/api/runs/" + created.run().id()))
                .body(created);
    }
}
