import { useQuery } from '@tanstack/react-query'
import { Link, useSearchParams } from 'react-router-dom'
import { fetchAcceptanceMetrics, fetchRuns, fetchVariants } from '../api/client'
import StatusBadge from '../components/StatusBadge'

function formatUsd(value: number | null): string {
  return value == null ? '—' : `$${value.toFixed(2)}`
}

function formatDate(iso: string | null): string {
  if (!iso) return '—'
  return new Date(iso).toLocaleString()
}

export default function DashboardPage() {
  const [searchParams, setSearchParams] = useSearchParams()
  const variantId = searchParams.get('variantId') ?? ''
  const status = searchParams.get('status') ?? ''

  const summaryRuns = useQuery({
    queryKey: ['runs', 'summary'],
    queryFn: () => fetchRuns({ size: 500 }),
  })
  const acceptance = useQuery({
    queryKey: ['metrics', 'acceptance', 'week'],
    queryFn: () => fetchAcceptanceMetrics('week'),
  })
  const variants = useQuery({ queryKey: ['variants'], queryFn: fetchVariants })
  const runs = useQuery({
    queryKey: ['runs', variantId, status],
    queryFn: () =>
      fetchRuns({ variantId: variantId || undefined, status: (status as never) || undefined, size: 50 }),
  })

  const all = summaryRuns.data?.items ?? []
  const succeeded = all.filter((r) => r.status === 'SUCCEEDED').length
  const failed = all.filter((r) => r.status === 'FAILED').length
  const running = all.filter((r) => r.status === 'RUNNING').length
  const totalCost = all.reduce((sum, r) => sum + (r.totalCostUsd ?? 0), 0)
  const accepted = (acceptance.data ?? []).reduce((sum, b) => sum + b.accepted, 0)
  const total = (acceptance.data ?? []).reduce((sum, b) => sum + b.total, 0)

  return (
    <div>
      <h1>Agent Runs</h1>

      <div className="cards">
        <div className="card">
          <div className="card-value">{succeeded}</div>
          <div className="card-label">Succeeded</div>
        </div>
        <div className="card">
          <div className="card-value">{failed}</div>
          <div className="card-label">Failed</div>
        </div>
        <div className="card">
          <div className="card-value">{running}</div>
          <div className="card-label">Running</div>
        </div>
        <div className="card">
          <div className="card-value">{formatUsd(totalCost)}</div>
          <div className="card-label">Total cost</div>
        </div>
        <div className="card">
          <div className="card-value">{total === 0 ? '—' : `${Math.round((100 * accepted) / total)}%`}</div>
          <div className="card-label">Acceptance rate</div>
        </div>
      </div>

      <div className="filters">
        <label>
          Variant{' '}
          <select
            value={variantId}
            onChange={(e) => {
              const next = new URLSearchParams(searchParams)
              if (e.target.value) next.set('variantId', e.target.value)
              else next.delete('variantId')
              setSearchParams(next)
            }}
          >
            <option value="">All</option>
            {(variants.data ?? []).map((v) => (
              <option key={v.id} value={v.id}>
                {v.name}
              </option>
            ))}
          </select>
        </label>
        <label>
          Status{' '}
          <select
            value={status}
            onChange={(e) => {
              const next = new URLSearchParams(searchParams)
              if (e.target.value) next.set('status', e.target.value)
              else next.delete('status')
              setSearchParams(next)
            }}
          >
            <option value="">All</option>
            <option value="RUNNING">Running</option>
            <option value="SUCCEEDED">Succeeded</option>
            <option value="FAILED">Failed</option>
          </select>
        </label>
      </div>

      {runs.isLoading && <p>Loading runs…</p>}
      {runs.isError && <p className="error">Failed to load runs.</p>}

      {runs.data && (
        <table className="runs-table">
          <thead>
            <tr>
              <th>Started</th>
              <th>Repo</th>
              <th>Branch</th>
              <th>Model</th>
              <th>Variant</th>
              <th>Cost</th>
              <th>Tokens</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {runs.data.items.map((run) => (
              <tr key={run.id}>
                <td>{formatDate(run.startedAt)}</td>
                <td>{run.repo}</td>
                <td>{run.branch}</td>
                <td>{run.model}</td>
                <td>{run.variantName}</td>
                <td>{formatUsd(run.totalCostUsd)}</td>
                <td>{run.totalTokens?.toLocaleString() ?? '—'}</td>
                <td>
                  <Link to={`/runs/${run.id}`}>
                    <StatusBadge status={run.status} />
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  )
}
