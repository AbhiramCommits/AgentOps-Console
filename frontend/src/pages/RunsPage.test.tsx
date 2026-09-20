import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { MemoryRouter } from 'react-router-dom'
import { fireEvent } from '@testing-library/react'
import { http, HttpResponse } from 'msw'
import RunsPage from './RunsPage'
import { server } from '../test/server'
import { clearCapturedRunRequests, capturedRunRequests, successHandlers } from '../test/handlers'
import { runFixtures, runsPage } from '../test/fixtures'

function renderPage(initialEntries: string[] = ['/']) {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={initialEntries}>
        <RunsPage />
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('RunsPage', () => {
  beforeEach(() => {
    clearCapturedRunRequests()
    server.use(...successHandlers)
  })

  it('renders runs in a table with acceptance and patch counts', async () => {
    renderPage()
    await waitFor(() => {
      expect(screen.getByText('acme/webapp')).toBeInTheDocument()
    })
    expect(screen.getByText('acme/api-gateway')).toBeInTheDocument()
    expect(within(screen.getByRole('table')).getByText('baseline-v1')).toBeInTheDocument()
    expect(screen.getByText('50%')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'acme/webapp' })).toHaveAttribute(
      'href',
      '/runs/11111111-1111-1111-1111-111111111111',
    )
  })

  it('sends variant and status filters to the API and shows the filtered result', async () => {
    const user = userEvent.setup()
    server.use(
      http.get('*/api/runs', ({ request }) => {
        capturedRunRequests.push(new URL(request.url))
        const url = new URL(request.url)
        const status = url.searchParams.get('status')
        const items = status === 'FAILED' ? [] : runFixtures
        return HttpResponse.json(runsPage(items))
      }),
    )
    renderPage()

    await screen.findByText('acme/webapp')
    await user.selectOptions(screen.getByLabelText('Prompt variant'), '22222222-2222-2222-2222-222222222222')
    await user.selectOptions(screen.getByLabelText('Status'), 'FAILED')

    await waitFor(() => {
      expect(screen.getByText('No runs match the current filters.')).toBeInTheDocument()
    })
    const last = capturedRunRequests[capturedRunRequests.length - 1]
    expect(last.searchParams.get('variantId')).toBe('22222222-2222-2222-2222-222222222222')
    expect(last.searchParams.get('status')).toBe('FAILED')
  })

  it('sends the date range as ISO timestamps', async () => {
    renderPage()
    await screen.findByText('acme/webapp')

    fireEvent.change(screen.getByLabelText('From'), { target: { value: '2026-08-01' } })
    fireEvent.change(screen.getByLabelText('To'), { target: { value: '2026-08-31' } })

    await waitFor(() => {
      const last = capturedRunRequests[capturedRunRequests.length - 1]
      expect(last?.searchParams.get('from')).toBe('2026-08-01T00:00:00Z')
    })
    const last = capturedRunRequests[capturedRunRequests.length - 1]
    expect(last.searchParams.get('to')).toBe('2026-08-31T23:59:59.999Z')
  })

  it('paginates server-side with prev/next controls', async () => {
    const user = userEvent.setup()
    server.use(
      http.get('*/api/runs', ({ request }) => {
        capturedRunRequests.push(new URL(request.url))
        const url = new URL(request.url)
        const page = Number(url.searchParams.get('page') ?? '0')
        const item = { ...runFixtures[0], id: `page-${page}` }
        return HttpResponse.json({ items: [item], page, size: 20, totalElements: 21, totalPages: 2 })
      }),
    )
    renderPage()

    await screen.findByText('acme/webapp')
    const next = screen.getByRole('button', { name: 'Next page' })
    const prev = screen.getByRole('button', { name: 'Previous page' })
    expect(prev).toBeDisabled()
    expect(screen.getByText('Page 1 of 2')).toBeInTheDocument()

    await user.click(next)

    await waitFor(() => {
      expect(screen.getByText('Page 2 of 2')).toBeInTheDocument()
    })
    const last = capturedRunRequests[capturedRunRequests.length - 1]
    expect(last.searchParams.get('page')).toBe('1')
  })

  it('shows the empty state with a clear-filters button when filters match nothing', async () => {
    server.use(
      http.get('*/api/runs', () => HttpResponse.json(runsPage([]))),
    )
    renderPage(['/?status=FAILED'])

    await waitFor(() => {
      expect(screen.getByText('No runs match the current filters.')).toBeInTheDocument()
    })
    expect(screen.getByRole('button', { name: 'Clear filters' })).toBeInTheDocument()
  })

  it('shows an error banner with retry when the API fails', async () => {
    server.use(http.get('*/api/runs', () => HttpResponse.json({ detail: 'boom' }, { status: 500 })))
    renderPage()

    await waitFor(() => {
      expect(screen.getByText(/Failed to load runs/)).toBeInTheDocument()
    })
    expect(screen.getByRole('button', { name: 'Retry' })).toBeInTheDocument()
  })
})
