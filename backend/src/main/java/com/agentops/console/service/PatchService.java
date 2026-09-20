package com.agentops.console.service;

import com.agentops.console.api.dto.response.PatchResponse;
import com.agentops.console.api.error.NotFoundException;
import com.agentops.console.repo.PatchRepository;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class PatchService {

    private final PatchRepository patchRepository;

    public PatchService(PatchRepository patchRepository) {
        this.patchRepository = patchRepository;
    }

    public PatchResponse getPatch(UUID id) {
        return patchRepository.findById(id)
                .map(PatchResponse::from)
                .orElseThrow(() -> new NotFoundException("patch not found: " + id));
    }
}
