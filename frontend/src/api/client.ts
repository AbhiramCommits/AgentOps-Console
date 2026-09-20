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

export interface VariantDto {
  id: string
  name: string
  description: string
  createdAt: string
}

export interface VariantStats {
  variantId: string
  variantName: string
  accepted: number
  totalVerdicts: number
}

export interface VariantWithStats {
  variant: VariantDto
  stats: VariantStats | null
}

export interface DashboardSummary {
  runningRuns: number
  succeededRuns: number
  failedRuns: number
  totalCostUsd: number
  totalTokens: number
  acceptedVerdicts: number
  rejectedVerdicts: number
  acceptedLast14Days: number
  rejectedLast14Days: number
}

async function get<T>(path: string): Promise<T> {
  const response = await fetch(path)
  if (!response.ok) {
    throw new Error(`GET ${path} failed: ${response.status} ${response.statusText}`)
  }
  return response.json() as Promise<T>
}

export function fetchRuns(params: { variantId?: string; status?: RunStatus } = {}): Promise<RunSummary[]> {
  const search = new URLSearchParams()
  if (params.variantId) search.set('variantId', params.variantId)
  if (params.status) search.set('status', params.status)
  const qs = search.toString()
  return get<RunSummary[]>(`/api/runs${qs ? `?${qs}` : ''}`)
}

export function fetchRun(id: string): Promise<RunSummary> {
  return get<RunSummary>(`/api/runs/${id}`)
}

export function fetchRunPatches(id: string): Promise<PatchDto[]> {
  return get<PatchDto[]>(`/api/runs/${id}/patches`)
}

export function fetchVariants(): Promise<VariantWithStats[]> {
  return get<VariantWithStats[]>('/api/variants')
}

export function fetchDashboardSummary(): Promise<DashboardSummary> {
  return get<DashboardSummary>('/api/dashboard/summary')
}
