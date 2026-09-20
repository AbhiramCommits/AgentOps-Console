import { render, screen, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { MemoryRouter } from 'react-router-dom'
import RunsPage from './RunsPage'
import * as api from '../api/client'
import type { PageResponse, RunSummary } from '../api/types'

vi.mock('../api/client', () => ({
  fetchRuns: vi.fn(),
  fetchRun: vi.fn(),
  fetchVariants: vi.fn(),
  fetchAcceptanceMetrics: vi.fn(),
  fetchCostLatencyMetrics: vi.fn(),
  reviewPatch: vi.fn(),
  amendPatchReview: vi.fn(),
}))

const runs: RunSummary[] = [
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

const page: PageResponse<RunSummary> = {
  items: runs,
  page: 0,
  size: 20,
  totalElements: 40,
  totalPages: 2,
}

function renderPage() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>
        <RunsPage />
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('RunsPage', () => {
  beforeEach(() => {
    vi.mocked(api.fetchRuns).mockResolvedValue(page)
    vi.mocked(api.fetchVariants).mockResolvedValue([])
  })

  it('renders runs in a table with acceptance and patch counts', async () => {
    renderPage()
    await waitFor(() => {
      expect(screen.getByText('acme/webapp')).toBeInTheDocument()
    })
    expect(screen.getByText('acme/api-gateway')).toBeInTheDocument()
    expect(screen.getByText('baseline-v1')).toBeInTheDocument()
    expect(screen.getByText('50%')).toBeInTheDocument()
    expect(screen.getByText('Succeeded', { selector: 'span' })).toBeInTheDocument()
    expect(screen.getByText('Running', { selector: 'span' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'acme/webapp' })).toHaveAttribute('href', '/runs/11111111-1111-1111-1111-111111111111')
  })

  it('shows the empty state and a clear-filters button', async () => {
    vi.mocked(api.fetchRuns).mockResolvedValue({ ...page, items: [], totalElements: 0, totalPages: 0 })
    const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } })
    render(
      <QueryClientProvider client={queryClient}>
        <MemoryRouter initialEntries={['/?status=FAILED']}>
          <RunsPage />
        </MemoryRouter>
      </QueryClientProvider>,
    )
    await waitFor(() => {
      expect(screen.getByText('No runs match the current filters.')).toBeInTheDocument()
    })
    expect(screen.getByRole('button', { name: 'Clear filters' })).toBeInTheDocument()
  })

  it('shows an error banner when the API fails', async () => {
    vi.mocked(api.fetchRuns).mockRejectedValue(new Error('boom'))
    renderPage()
    await waitFor(() => {
      expect(screen.getByText(/Failed to load runs/)).toBeInTheDocument()
    })
  })
})
