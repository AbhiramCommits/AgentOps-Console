package com.agentops.console.api.dto.response;

import com.agentops.console.domain.AgentRun;
import com.agentops.console.domain.Patch;

import java.util.List;

public record RunDetailResponse(
        RunSummaryResponse run,
        List<PatchResponse> patches
) {
    public static RunDetailResponse of(AgentRun run, List<Patch> patches) {
        return new RunDetailResponse(
                RunSummaryResponse.from(run),
                patches.stream().map(PatchResponse::from).toList()
        );
    }
}
