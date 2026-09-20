import { render, screen, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { MemoryRouter } from 'react-router-dom'
import DashboardPage from './DashboardPage'
import * as api from '../api/client'

vi.mock('../api/client', () => ({
  fetchRuns: vi.fn(),
  fetchRun: vi.fn(),
  fetchVariants: vi.fn(),
  fetchAcceptanceMetrics: vi.fn(),
  fetchCostLatencyMetrics: vi.fn(),
}))

const runs: api.RunSummary[] = [
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
  },
]

const page: api.PageResponse<api.RunSummary> = {
  items: runs,
  page: 0,
  size: 50,
  totalElements: 40,
  totalPages: 1,
}

const acceptance: api.AcceptanceBucket[] = [
  {
    variantId: '22222222-2222-2222-2222-222222222222',
    variantName: 'baseline-v1',
    bucketStart: '2026-09-14T00:00:00Z',
    accepted: 6,
    total: 14,
    acceptanceRate: 0.43,
  },
  {
    variantId: '44444444-4444-4444-4444-444444444444',
    variantName: 'spec-driven-v2',
    bucketStart: '2026-09-14T00:00:00Z',
    accepted: 7,
    total: 15,
    acceptanceRate: 0.47,
  },
]

function renderDashboard() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>
        <DashboardPage />
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('DashboardPage', () => {
  beforeEach(() => {
    vi.mocked(api.fetchRuns).mockResolvedValue(page)
    vi.mocked(api.fetchVariants).mockResolvedValue([])
    vi.mocked(api.fetchAcceptanceMetrics).mockResolvedValue(acceptance)
  })

  it('shows summary cards', async () => {
    renderDashboard()
    await waitFor(() => {
      expect(screen.getByText('$15.55')).toBeInTheDocument()
    })
    expect(screen.getByText('45%')).toBeInTheDocument()
    expect(screen.getByText('Succeeded', { selector: '.card-label' })).toBeInTheDocument()
  })

  it('lists runs with repo, variant and status', async () => {
    renderDashboard()
    await waitFor(() => {
      expect(screen.getByText('acme/webapp')).toBeInTheDocument()
    })
    expect(screen.getByText('acme/api-gateway')).toBeInTheDocument()
    expect(screen.getByText('baseline-v1')).toBeInTheDocument()
    expect(screen.getByText('Succeeded', { selector: '.status-badge' })).toBeInTheDocument()
    expect(screen.getByText('Running', { selector: '.status-badge' })).toBeInTheDocument()
  })

  it('shows an error when the API fails', async () => {
    vi.mocked(api.fetchRuns).mockRejectedValue(new Error('boom'))
    renderDashboard()
    await waitFor(() => {
      expect(screen.getByText('Failed to load runs.')).toBeInTheDocument()
    })
  })
})
