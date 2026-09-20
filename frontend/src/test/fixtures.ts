import type { PageResponse, RunSummary, Variant } from '../api/types'

export const variantFixtures: Variant[] = [
  {
    id: '22222222-2222-2222-2222-222222222222',
    name: 'baseline-v1',
    description: 'Control prompt',
    template: 'You are helpful.',
    createdAt: '2026-07-01T00:00:00Z',
  },
  {
    id: '44444444-4444-4444-4444-444444444444',
    name: 'spec-driven-v2',
    description: 'Constraints section',
    template: 'You are helpful. Constraints apply.',
    createdAt: '2026-07-08T00:00:00Z',
  },
]

export const runFixtures: RunSummary[] = [
  {
    id: '11111111-1111-1111-1111-111111111111',
    tool: 'agentops-codex',
    repo: 'acme/webapp',
    branch: 'main',
    model: 'gpt-4o',
    status: 'SUCCEEDED',
    variantId: '22222222-2222-2222-2222-222222222222',
    variantName: 'baseline-v1',
    startedAt: '2026-09-20T10:00:00Z',
    finishedAt: '2026-09-20T10:30:00Z',
    totalCostUsd: 12.345,
    totalTokens: 42000,
    patchCount: 5,
    reviewedPatches: 4,
    acceptedPatches: 2,
  },
  {
    id: '33333333-3333-3333-3333-333333333333',
    tool: 'agentops-claude-code',
    repo: 'acme/api-gateway',
    branch: 'feat/rate-limiter',
    model: 'claude-sonnet-4',
    status: 'RUNNING',
    variantId: '44444444-4444-4444-4444-444444444444',
    variantName: 'spec-driven-v2',
    startedAt: '2026-09-20T12:00:00Z',
    finishedAt: null,
    totalCostUsd: 3.21,
    totalTokens: 9000,
    patchCount: 3,
    reviewedPatches: 0,
    acceptedPatches: 0,
  },
]

export function runsPage(items: RunSummary[]): PageResponse<RunSummary> {
  return { items, page: 0, size: 20, totalElements: items.length, totalPages: 1 }
}
