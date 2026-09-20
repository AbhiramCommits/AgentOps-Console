package com.agentops.console.api;

import com.agentops.console.api.dto.response.AcceptanceBucketResponse;
import com.agentops.console.api.dto.response.PageResponse;
import com.agentops.console.api.dto.response.PatchResponse;
import com.agentops.console.api.dto.response.RunDetailResponse;
import com.agentops.console.api.dto.response.RunSummaryResponse;
import com.agentops.console.api.dto.response.VerdictResponse;
import com.agentops.console.api.dto.response.VariantResponse;
import com.agentops.console.api.error.BusinessValidationException;
import com.agentops.console.api.error.ConflictException;
import com.agentops.console.api.error.NotFoundException;
import com.agentops.console.service.MetricsService;
import com.agentops.console.service.PatchService;
import com.agentops.console.service.ReviewService;
import com.agentops.console.service.RunService;
import com.agentops.console.service.VariantService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest
class ControllerSliceTest {

    private static final UUID RUN_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID PATCH_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID VARIANT_ID = UUID.fromString("33333333-3333-3333-3333-333333333333");

    private static final String PROBLEM_JSON = "application/problem+json";

    @MockBean
    private RunService runService;

    @MockBean
    private PatchService patchService;

    @MockBean
    private ReviewService reviewService;

    @MockBean
    private VariantService variantService;

    @MockBean
    private MetricsService metricsService;

    @org.springframework.beans.factory.annotation.Autowired
    private MockMvc mockMvc;

    private RunSummaryResponse runSummary;

    @BeforeEach
    void setUp() {
        runSummary = new RunSummaryResponse(
                RUN_ID, "agentops-codex", "acme/webapp", "main", "gpt-4o", "SUCCEEDED",
                VARIANT_ID, "baseline-v1", OffsetDateTime.now(), OffsetDateTime.now().plusMinutes(20),
                new java.math.BigDecimal("4.20"), 1000, 5, 4, 2);
    }

    private static VerdictResponse verdictResponse() {
        return new VerdictResponse(
                UUID.randomUUID(), PATCH_ID, "alice", "ACCEPTED", null, OffsetDateTime.now());
    }

    // ---------------------------------------------------------------- runs

    @Test
    void listRunsReturnsPage() throws Exception {
        when(runService.list(any(), any(), any(), any(), eq(0), eq(20)))
                .thenReturn(new PageResponse<>(List.of(runSummary), 0, 20, 1, 1));

        mockMvc.perform(get("/api/runs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(1))
                .andExpect(jsonPath("$.items[0].id").value(RUN_ID.toString()))
                .andExpect(jsonPath("$.items[0].patchCount").value(5))
                .andExpect(jsonPath("$.items[0].acceptedPatches").value(2));
    }

    @Test
    void invalidPageParameterIsBadRequestProblemDetail() throws Exception {
        mockMvc.perform(get("/api/runs").param("page", "abc"))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(PROBLEM_JSON))
                .andExpect(jsonPath("$.title").value("Invalid parameter"))
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.instance").value("/api/runs"));
    }

    @Test
    void getRunReturnsDetail() throws Exception {
        when(runService.getDetail(RUN_ID))
                .thenReturn(new RunDetailResponse(runSummary, List.of()));

        mockMvc.perform(get("/api/runs/" + RUN_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.run.id").value(RUN_ID.toString()))
                .andExpect(jsonPath("$.patches.length()").value(0));
    }

    @Test
    void ingestRunWithBlankToolIsValidationProblemDetail() throws Exception {
        mockMvc.perform(post("/api/runs")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"tool": "", "repo": "r", "branch": "b", "model": "m",
                                 "variantId": "%s"}
                                """.formatted(VARIANT_ID)))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(PROBLEM_JSON))
                .andExpect(jsonPath("$.title").value("Validation failed"))
                .andExpect(jsonPath("$.type").value("https://api.agentops.dev/errors/validation"))
                .andExpect(jsonPath("$.errors.tool").exists())
                .andExpect(jsonPath("$.instance").value("/api/runs"));
    }

    @Test
    void ingestValidRunReturnsCreatedWithLocation() throws Exception {
        when(runService.ingest(any())).thenReturn(new RunDetailResponse(runSummary, List.of()));

        mockMvc.perform(post("/api/runs")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"tool": "agentops-codex", "repo": "r", "branch": "b", "model": "m",
                                 "variantId": "%s"}
                                """.formatted(VARIANT_ID)))
                .andExpect(status().isCreated())
                .andExpect(header().string("Location", "/api/runs/" + RUN_ID))
                .andExpect(jsonPath("$.run.id").value(RUN_ID.toString()));
    }

    // ---------------------------------------------------------------- patches & reviews

    @Test
    void getPatchReturnsPatch() throws Exception {
        when(patchService.getPatch(PATCH_ID))
                .thenReturn(new PatchResponse(PATCH_ID, RUN_ID, "src/main.go", "diff", 1, 1, 100, new java.math.BigDecimal("0.50"),
                        OffsetDateTime.now(), null));

        mockMvc.perform(get("/api/patches/" + PATCH_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.filePath").value("src/main.go"))
                .andExpect(jsonPath("$.verdict").doesNotExist());
    }

    @Test
    void getUnknownPatchIsNotFoundProblemDetail() throws Exception {
        when(patchService.getPatch(PATCH_ID))
                .thenThrow(new NotFoundException("patch not found: " + PATCH_ID));

        mockMvc.perform(get("/api/patches/" + PATCH_ID))
                .andExpect(status().isNotFound())
                .andExpect(content().contentTypeCompatibleWith(PROBLEM_JSON))
                .andExpect(jsonPath("$.title").value("Resource not found"))
                .andExpect(jsonPath("$.status").value(404))
                .andExpect(jsonPath("$.instance").value("/api/patches/" + PATCH_ID));
    }

    @Test
    void reviewPatchReturnsCreatedVerdict() throws Exception {
        when(reviewService.createReview(eq(PATCH_ID), any())).thenReturn(verdictResponse());

        mockMvc.perform(post("/api/patches/" + PATCH_ID + "/review")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reviewer": "alice", "decision": "ACCEPTED"}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.decision").value("ACCEPTED"));
    }

    @Test
    void duplicateReviewIsConflictProblemDetail() throws Exception {
        when(reviewService.createReview(eq(PATCH_ID), any()))
                .thenThrow(new ConflictException("already has a review verdict"));

        mockMvc.perform(post("/api/patches/" + PATCH_ID + "/review")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reviewer": "alice", "decision": "ACCEPTED"}
                                """))
                .andExpect(status().isConflict())
                .andExpect(content().contentTypeCompatibleWith(PROBLEM_JSON))
                .andExpect(jsonPath("$.title").value("State conflict"))
                .andExpect(jsonPath("$.status").value(409))
                .andExpect(jsonPath("$.type").value("https://api.agentops.dev/errors/conflict"));
    }

    @Test
    void rejectedReviewWithoutReasonIsBusinessValidationProblemDetail() throws Exception {
        when(reviewService.createReview(eq(PATCH_ID), any()))
                .thenThrow(new BusinessValidationException("overrideReason is required when decision is REJECTED"));

        mockMvc.perform(post("/api/patches/" + PATCH_ID + "/review")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reviewer": "alice", "decision": "REJECTED"}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Business rule violation"))
                .andExpect(jsonPath("$.detail").value("overrideReason is required when decision is REJECTED"));
    }

    @Test
    void amendReviewReturnsUpdatedVerdict() throws Exception {
        when(reviewService.amendReview(eq(PATCH_ID), any())).thenReturn(verdictResponse());

        mockMvc.perform(put("/api/patches/" + PATCH_ID + "/review")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reviewer": "diana", "decision": "ACCEPTED"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.reviewer").value("alice"));
    }

    // ---------------------------------------------------------------- variants

    @Test
    void listVariantsReturnsVariants() throws Exception {
        when(variantService.list()).thenReturn(List.of(new VariantResponse(
                VARIANT_ID, "baseline-v1", "desc", "template", OffsetDateTime.now())));

        mockMvc.perform(get("/api/variants"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].name").value("baseline-v1"));
    }

    @Test
    void createDuplicateVariantIsConflict() throws Exception {
        when(variantService.create(any())).thenThrow(new ConflictException("name already exists"));

        mockMvc.perform(post("/api/variants")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name": "baseline-v1", "template": "x"}
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.title").value("State conflict"));
    }

    // ---------------------------------------------------------------- metrics

    @Test
    void acceptanceMetricsReturnsBuckets() throws Exception {
        when(metricsService.acceptance(any())).thenReturn(List.of(
                new AcceptanceBucketResponse(VARIANT_ID, "baseline-v1", OffsetDateTime.now(), 2L, 4L, 0.5)));

        mockMvc.perform(get("/api/metrics/acceptance"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].acceptanceRate").value(0.5));
    }

    @Test
    void invalidBucketIsBadRequestProblemDetail() throws Exception {
        mockMvc.perform(get("/api/metrics/acceptance").param("bucket", "month"))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(PROBLEM_JSON))
                .andExpect(jsonPath("$.title").value("Invalid parameter"))
                .andExpect(jsonPath("$.instance").value("/api/metrics/acceptance"));
    }

    // ---------------------------------------------------------------- advice

    @Test
    void malformedJsonIsBadRequestProblemDetail() throws Exception {
        mockMvc.perform(post("/api/runs")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{not valid json"))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(PROBLEM_JSON))
                .andExpect(jsonPath("$.title").value("Malformed request"))
                .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void dataIntegrityViolationIsConflictProblemDetail() throws Exception {
        when(variantService.create(any())).thenThrow(new DataIntegrityViolationException("unique constraint"));

        mockMvc.perform(post("/api/variants")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name": "dup", "template": "x"}
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.title").value("State conflict"))
                .andExpect(jsonPath("$.detail").value("The change violates a database constraint"));
    }

    @Test
    void unexpectedExceptionIsInternalServerErrorProblemDetail() throws Exception {
        when(runService.getDetail(RUN_ID)).thenThrow(new IllegalStateException("boom"));

        mockMvc.perform(get("/api/runs/" + RUN_ID))
                .andExpect(status().isInternalServerError())
                .andExpect(content().contentTypeCompatibleWith(PROBLEM_JSON))
                .andExpect(jsonPath("$.title").value("Internal server error"))
                .andExpect(jsonPath("$.status").value(500));
    }
}
