import { useQuery } from '@tanstack/react-query'
import { Link, useSearchParams } from 'react-router-dom'
import { fetchDashboardSummary, fetchRuns, fetchVariants } from '../api/client'
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

  const summary = useQuery({ queryKey: ['dashboard'], queryFn: fetchDashboardSummary })
  const variants = useQuery({ queryKey: ['variants'], queryFn: fetchVariants })
  const runs = useQuery({
    queryKey: ['runs', variantId, status],
    queryFn: () => fetchRuns({ variantId: variantId || undefined, status: (status as never) || undefined }),
  })

  return (
    <div>
      <h1>Agent Runs</h1>

      {summary.data && (
        <div className="cards">
          <div className="card">
            <div className="card-value">{summary.data.succeededRuns}</div>
            <div className="card-label">Succeeded</div>
          </div>
          <div className="card">
            <div className="card-value">{summary.data.failedRuns}</div>
            <div className="card-label">Failed</div>
          </div>
          <div className="card">
            <div className="card-value">{summary.data.runningRuns}</div>
            <div className="card-label">Running</div>
          </div>
          <div className="card">
            <div className="card-value">{formatUsd(summary.data.totalCostUsd)}</div>
            <div className="card-label">Total cost</div>
          </div>
          <div className="card">
            <div className="card-value">
              {summary.data.acceptedVerdicts + summary.data.rejectedVerdicts === 0
                ? '—'
                : `${Math.round((100 * summary.data.acceptedVerdicts) / (summary.data.acceptedVerdicts + summary.data.rejectedVerdicts))}%`}
            </div>
            <div className="card-label">Acceptance rate</div>
          </div>
        </div>
      )}

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
              <option key={v.variant.id} value={v.variant.id}>
                {v.variant.name}
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
            {runs.data.map((run) => (
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
