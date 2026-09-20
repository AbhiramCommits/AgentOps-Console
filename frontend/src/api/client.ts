export type RunStatus = 'RUNNING' | 'SUCCEEDED' | 'FAILED'

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
}

export interface VerdictDto {
  id: string
  patchId: string
  reviewer: string
  decision: 'ACCEPTED' | 'REJECTED'
  overrideReason: string | null
  decidedAt: string
}

export interface PatchDto {
  id: string
  runId: string
  filePath: string
  diffUnified: string
  linesAdded: number
  linesRemoved: number
  latencyMs: number
  costUsd: number
  createdAt: string
  verdict: VerdictDto | null
}

export interface RunDetail {
  run: RunSummary
  patches: PatchDto[]
}

export interface VariantDto {
  id: string
  name: string
  description: string | null
  template: string
  createdAt: string
}

export interface PageResponse<T> {
  items: T[]
  page: number
  size: number
  totalElements: number
  totalPages: number
}

export interface AcceptanceBucket {
  variantId: string
  variantName: string
  bucketStart: string
  accepted: number
  total: number
  acceptanceRate: number
}

export interface CostLatencyBucket {
  variantId: string
  variantName: string
  bucketStart: string
  totalCostUsd: number
  p50LatencyMs: number
  p95LatencyMs: number
  patchCount: number
}

async function get<T>(path: string): Promise<T> {
  const response = await fetch(path)
  if (!response.ok) {
    throw new Error(`GET ${path} failed: ${response.status} ${response.statusText}`)
  }
  return response.json() as Promise<T>
}

export function fetchRuns(params: {
  variantId?: string
  status?: RunStatus
  page?: number
  size?: number
} = {}): Promise<PageResponse<RunSummary>> {
  const search = new URLSearchParams()
  if (params.variantId) search.set('variantId', params.variantId)
  if (params.status) search.set('status', params.status)
  if (params.page != null) search.set('page', String(params.page))
  if (params.size != null) search.set('size', String(params.size))
  const qs = search.toString()
  return get<PageResponse<RunSummary>>(`/api/runs${qs ? `?${qs}` : ''}`)
}

export function fetchRun(id: string): Promise<RunDetail> {
  return get<RunDetail>(`/api/runs/${id}`)
}

export function fetchVariants(): Promise<VariantDto[]> {
  return get<VariantDto[]>('/api/variants')
}

export function fetchAcceptanceMetrics(bucket: 'day' | 'week' = 'day'): Promise<AcceptanceBucket[]> {
  return get<AcceptanceBucket[]>(`/api/metrics/acceptance?bucket=${bucket}`)
}

export function fetchCostLatencyMetrics(bucket: 'day' | 'week' = 'day'): Promise<CostLatencyBucket[]> {
  return get<CostLatencyBucket[]>(`/api/metrics/cost-latency?bucket=${bucket}`)
}
