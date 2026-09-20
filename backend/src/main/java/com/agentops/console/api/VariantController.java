package com.agentops.console.api;

import com.agentops.console.api.dto.request.CreateVariantRequest;
import com.agentops.console.api.dto.response.VariantResponse;
import com.agentops.console.service.VariantService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping("/api/variants")
public class VariantController {

    private final VariantService variantService;

    public VariantController(VariantService variantService) {
        this.variantService = variantService;
    }

    @GetMapping
    public List<VariantResponse> list() {
        return variantService.list();
    }

    @PostMapping
    public ResponseEntity<VariantResponse> create(@Valid @RequestBody CreateVariantRequest request) {
        VariantResponse created = variantService.create(request);
        return ResponseEntity
                .created(URI.create("/api/variants/" + created.id()))
                .body(created);
    }
}
