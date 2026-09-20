// TypeScript types for every AgentOps Console API payload.
// Mirrors the Spring Boot DTOs in backend/src/main/java/com/agentops/console/api/dto.

export type RunStatus = 'RUNNING' | 'SUCCEEDED' | 'FAILED'

export type VerdictDecision = 'ACCEPTED' | 'REJECTED'

export type BucketGranularity = 'day' | 'week'

// RFC 7807 problem detail returned by the backend's @RestControllerAdvice.
export interface ProblemDetail {
  type?: string
  title?: string
  status?: number
  detail?: string
  instance?: string
  errors?: Record<string, string>
}

// GET /api/runs items (RunSummaryResponse)
export interface RunSummary {
  id: string
  tool: string
  repo: string
  branch: string
  model: string
  status: RunStatus
  variantId: string
  variantName: string
  startedAt: string
  finishedAt: string | null
  totalCostUsd: number | null
  totalTokens: number | null
  patchCount: number
  reviewedPatches: number
  acceptedPatches: number
}

// VerdictResponse
export interface Verdict {
  id: string
  patchId: string
  reviewer: string
  decision: VerdictDecision
  overrideReason: string | null
  decidedAt: string
}

// PatchResponse
export interface Patch {
  id: string
  runId: string
  filePath: string
  diffUnified: string
  linesAdded: number
  linesRemoved: number
  latencyMs: number
  costUsd: number
  createdAt: string
  verdict: Verdict | null
}

// RunDetailResponse — GET /api/runs/{id}, POST /api/runs
export interface RunDetail {
  run: RunSummary
  patches: Patch[]
}

// VariantResponse — GET /api/variants, POST /api/variants
export interface Variant {
  id: string
  name: string
  description: string | null
  template: string
  createdAt: string
}

// PageResponse<T> — GET /api/runs
export interface PageResponse<T> {
  items: T[]
  page: number
  size: number
  totalElements: number
  totalPages: number
}

// AcceptanceBucketResponse — GET /api/metrics/acceptance
export interface AcceptanceBucket {
  variantId: string
  variantName: string
  bucketStart: string
  accepted: number
  total: number
  acceptanceRate: number
}

// CostLatencyBucketResponse — GET /api/metrics/cost-latency
export interface CostLatencyBucket {
  variantId: string
  variantName: string
  bucketStart: string
  totalCostUsd: number
  p50LatencyMs: number
  p95LatencyMs: number
  patchCount: number
}

// POST /api/patches/{id}/review, PUT /api/patches/{id}/review (ReviewRequest)
export interface ReviewRequest {
  reviewer: string
  decision: VerdictDecision
  overrideReason?: string
}

// POST /api/runs (CreateRunRequest)
export interface CreateRunRequest {
  tool: string
  repo: string
  branch: string
  model: string
  variantId: string
  status?: RunStatus
  startedAt?: string
  finishedAt?: string
  totalTokens?: number
  patches?: CreatePatchRequest[]
}

export interface CreatePatchRequest {
  filePath: string
  diffUnified: string
  linesAdded: number
  linesRemoved: number
  latencyMs: number
  costUsd: number
}

// POST /api/variants (CreateVariantRequest)
export interface CreateVariantRequest {
  name: string
  template: string
  description?: string
}
