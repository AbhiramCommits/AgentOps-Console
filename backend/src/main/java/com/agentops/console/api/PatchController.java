package com.agentops.console.api;

import com.agentops.console.api.dto.request.ReviewRequest;
import com.agentops.console.api.dto.response.PatchResponse;
import com.agentops.console.api.dto.response.VerdictResponse;
import com.agentops.console.service.PatchService;
import com.agentops.console.service.ReviewService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;
import java.util.UUID;

@RestController
@RequestMapping("/api/patches")
public class PatchController {

    private final PatchService patchService;
    private final ReviewService reviewService;

    public PatchController(PatchService patchService, ReviewService reviewService) {
        this.patchService = patchService;
        this.reviewService = reviewService;
    }

    @GetMapping("/{id}")
    public PatchResponse get(@PathVariable UUID id) {
        return patchService.getPatch(id);
    }

    @PostMapping("/{id}/review")
    public ResponseEntity<VerdictResponse> review(@PathVariable UUID id,
                                                  @Valid @RequestBody ReviewRequest request) {
        VerdictResponse verdict = reviewService.createReview(id, request);
        return ResponseEntity
                .created(URI.create("/api/patches/" + id + "/review"))
                .body(verdict);
    }

    @PutMapping("/{id}/review")
    public VerdictResponse amendReview(@PathVariable UUID id,
                                       @Valid @RequestBody ReviewRequest request) {
        return reviewService.amendReview(id, request);
    }
}
