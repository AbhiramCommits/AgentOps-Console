package com.agentops.console.api.dto.response;

import com.agentops.console.domain.AgentRun;
import com.agentops.console.domain.Patch;
import com.agentops.console.domain.VerdictDecision;

import java.util.List;

public record RunDetailResponse(
        RunSummaryResponse run,
        List<PatchResponse> patches
) {
    public static RunDetailResponse of(AgentRun run, List<Patch> patches) {
        int reviewed = 0;
        int accepted = 0;
        for (Patch patch : patches) {
            if (patch.getReviewVerdict() != null) {
                reviewed++;
                if (patch.getReviewVerdict().getDecision() == VerdictDecision.ACCEPTED) {
                    accepted++;
                }
            }
        }
        RunSummaryResponse.RunPatchStats stats =
                new RunSummaryResponse.RunPatchStats(patches.size(), reviewed, accepted);
        return new RunDetailResponse(
                RunSummaryResponse.from(run, stats),
                patches.stream().map(PatchResponse::from).toList()
        );
    }
}
