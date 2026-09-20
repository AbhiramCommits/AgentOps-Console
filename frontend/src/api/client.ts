import type {
  AcceptanceBucket,
  BucketGranularity,
  CostLatencyBucket,
  PageResponse,
  ProblemDetail,
  ReviewRequest,
  RunDetail,
  RunStatus,
  RunSummary,
  Variant,
  Verdict,
} from './types'

export class ApiError extends Error {
  readonly status: number
  readonly problem: ProblemDetail | null

  constructor(status: number, message: string, problem: ProblemDetail | null) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.problem = problem
  }
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(path, init)
  if (!response.ok) {
    let problem: ProblemDetail | null = null
    try {
      problem = (await response.json()) as ProblemDetail
    } catch {
      problem = null
    }
    throw new ApiError(response.status, problem?.detail ?? response.statusText, problem)
  }
  return (await response.json()) as T
}

function jsonInit(method: string, body: unknown): RequestInit {
  return {
    method,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  }
}

export interface RunFilters {
  variantId?: string
  status?: RunStatus
  from?: string
  to?: string
  page?: number
  size?: number
}

export function fetchRuns(filters: RunFilters = {}): Promise<PageResponse<RunSummary>> {
  const search = new URLSearchParams()
  if (filters.variantId) search.set('variantId', filters.variantId)
  if (filters.status) search.set('status', filters.status)
  if (filters.from) search.set('from', filters.from)
  if (filters.to) search.set('to', filters.to)
  if (filters.page != null) search.set('page', String(filters.page))
  if (filters.size != null) search.set('size', String(filters.size))
  const qs = search.toString()
  return request<PageResponse<RunSummary>>(`/api/runs${qs ? `?${qs}` : ''}`)
}

export function fetchRun(id: string): Promise<RunDetail> {
  return request<RunDetail>(`/api/runs/${id}`)
}

export function fetchVariants(): Promise<Variant[]> {
  return request<Variant[]>('/api/variants')
}

export function fetchAcceptanceMetrics(bucket: BucketGranularity = 'day'): Promise<AcceptanceBucket[]> {
  return request<AcceptanceBucket[]>(`/api/metrics/acceptance?bucket=${bucket}`)
}

export function fetchCostLatencyMetrics(bucket: BucketGranularity = 'day'): Promise<CostLatencyBucket[]> {
  return request<CostLatencyBucket[]>(`/api/metrics/cost-latency?bucket=${bucket}`)
}

export function reviewPatch(patchId: string, body: ReviewRequest): Promise<Verdict> {
  return request<Verdict>(`/api/patches/${patchId}/review`, jsonInit('POST', body))
}

export function amendPatchReview(patchId: string, body: ReviewRequest): Promise<Verdict> {
  return request<Verdict>(`/api/patches/${patchId}/review`, jsonInit('PUT', body))
}
