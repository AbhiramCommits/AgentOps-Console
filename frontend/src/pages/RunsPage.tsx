import { useQuery, keepPreviousData } from '@tanstack/react-query'
import { Link, useSearchParams } from 'react-router-dom'
import { fetchRuns, fetchVariants } from '../api/client'
import type { RunStatus } from '../api/types'
import StatusBadge from '../components/StatusBadge'
import Pagination from '../components/Pagination'
import { SkeletonTable } from '../components/Skeleton'
import { formatDate, formatDuration, formatPercent, formatUsd } from '../lib/format'
import styles from './RunsPage.module.css'

const PAGE_SIZE = 20

const STATUS_OPTIONS: Array<{ value: RunStatus; label: string }> = [
  { value: 'RUNNING', label: 'Running' },
  { value: 'SUCCEEDED', label: 'Succeeded' },
  { value: 'FAILED', label: 'Failed' },
]

export default function RunsPage() {
  const [searchParams, setSearchParams] = useSearchParams()
  const variantId = searchParams.get('variantId') ?? ''
  const status = (searchParams.get('status') ?? '') as RunStatus | ''
  const fromDate = searchParams.get('from') ?? ''
  const toDate = searchParams.get('to') ?? ''
  const page = Math.max(0, Number(searchParams.get('page') ?? '0') || 0)

  const variants = useQuery({ queryKey: ['variants'], queryFn: fetchVariants })

  const runs = useQuery({
    queryKey: ['runs', { variantId, status, from: fromDate, to: toDate, page }],
    queryFn: () =>
      fetchRuns({
        variantId: variantId || undefined,
        status: status || undefined,
        from: fromDate ? `${fromDate}T00:00:00Z` : undefined,
        to: toDate ? `${toDate}T23:59:59.999Z` : undefined,
        page,
        size: PAGE_SIZE,
      }),
    placeholderData: keepPreviousData,
  })

  function updateParam(key: string, value: string) {
    const next = new URLSearchParams(searchParams)
    if (value) next.set(key, value)
    else next.delete(key)
    if (key !== 'page') next.delete('page')
    setSearchParams(next)
  }

  function clearFilters() {
    setSearchParams(new URLSearchParams())
  }

  const hasFilters = variantId !== '' || status !== '' || fromDate !== '' || toDate !== ''
  const items = runs.data?.items ?? []

  return (
    <div>
      <h1>Agent Runs</h1>

      <form className={styles.filters} onSubmit={(event) => event.preventDefault()}>
        <label className={styles.filterField}>
          <span className={styles.filterLabel}>Prompt variant</span>
          <select value={variantId} onChange={(event) => updateParam('variantId', event.target.value)}>
            <option value="">All</option>
            {(variants.data ?? []).map((variant) => (
              <option key={variant.id} value={variant.id}>
                {variant.name}
              </option>
            ))}
          </select>
        </label>
        <label className={styles.filterField}>
          <span className={styles.filterLabel}>Status</span>
          <select value={status} onChange={(event) => updateParam('status', event.target.value)}>
            <option value="">All</option>
            {STATUS_OPTIONS.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </label>
        <label className={styles.filterField}>
          <span className={styles.filterLabel}>From</span>
          <input type="date" value={fromDate} onChange={(event) => updateParam('from', event.target.value)} />
        </label>
        <label className={styles.filterField}>
          <span className={styles.filterLabel}>To</span>
          <input type="date" value={toDate} onChange={(event) => updateParam('to', event.target.value)} />
        </label>
      </form>

      {runs.isError && (
        <div className={styles.banner} role="alert">
          Failed to load runs.{' '}
          <button type="button" onClick={() => runs.refetch()}>
            Retry
          </button>
        </div>
      )}

      {runs.isPending && <SkeletonTable rows={8} columns={8} />}

      {!runs.isPending && items.length === 0 && (
        <div className={styles.empty}>
          <p>No runs match the current filters.</p>
          {hasFilters && (
            <button type="button" className={styles.clearButton} onClick={clearFilters}>
              Clear filters
            </button>
          )}
        </div>
      )}

      {!runs.isPending && items.length > 0 && (
        <div className={styles.tableWrap}>
          <table className={styles.table}>
            <caption className="sr-only">Agent runs, newest first</caption>
            <thead>
              <tr>
                <th scope="col">Started</th>
                <th scope="col">Repo</th>
                <th scope="col">Tool</th>
                <th scope="col">Model</th>
                <th scope="col">Variant</th>
                <th scope="col">Duration</th>
                <th scope="col">Cost</th>
                <th scope="col">Patches</th>
                <th scope="col">Acceptance</th>
                <th scope="col">Status</th>
              </tr>
            </thead>
            <tbody className={runs.isFetching ? styles.fetching : undefined}>
              {items.map((run) => (
                <tr key={run.id}>
                  <td className={styles.nowrap}>{formatDate(run.startedAt)}</td>
                  <td>
                    <Link to={`/runs/${run.id}`} className={styles.repoLink}>
                      {run.repo}
                    </Link>
                    <div className={styles.subText}>{run.branch}</div>
                  </td>
                  <td>{run.tool}</td>
                  <td>{run.model}</td>
                  <td>{run.variantName}</td>
                  <td className={styles.nowrap}>{formatDuration(run.startedAt, run.finishedAt)}</td>
                  <td className={styles.nowrap}>{formatUsd(run.totalCostUsd)}</td>
                  <td>{run.patchCount}</td>
                  <td>
                    {run.reviewedPatches === 0
                      ? '—'
                      : formatPercent(run.acceptedPatches / run.reviewedPatches)}
                  </td>
                  <td>
                    <StatusBadge status={run.status} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {runs.data && items.length > 0 && (
        <Pagination
          page={runs.data.page}
          totalPages={runs.data.totalPages}
          totalElements={runs.data.totalElements}
          onPageChange={(nextPage) => updateParam('page', String(nextPage))}
        />
      )}
    </div>
  )
}
