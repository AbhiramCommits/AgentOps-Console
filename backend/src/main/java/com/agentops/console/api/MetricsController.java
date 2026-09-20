package com.agentops.console.api;

import com.agentops.console.api.dto.response.AcceptanceBucketResponse;
import com.agentops.console.api.dto.response.CostLatencyBucketResponse;
import com.agentops.console.service.BucketGranularity;
import com.agentops.console.service.MetricsService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/metrics")
public class MetricsController {

    private final MetricsService metricsService;

    public MetricsController(MetricsService metricsService) {
        this.metricsService = metricsService;
    }

    @GetMapping("/acceptance")
    public List<AcceptanceBucketResponse> acceptance(
            @RequestParam(defaultValue = "day") BucketGranularity bucket) {
        return metricsService.acceptance(bucket);
    }

    @GetMapping("/cost-latency")
    public List<CostLatencyBucketResponse> costLatency(
            @RequestParam(defaultValue = "day") BucketGranularity bucket) {
        return metricsService.costLatency(bucket);
    }
}
