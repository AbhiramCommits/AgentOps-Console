import { useQuery } from '@tanstack/react-query'
import { Link, useParams } from 'react-router-dom'
import { fetchRun } from '../api/client'
import StatusBadge, { VerdictBadge } from '../components/StatusBadge'

export default function RunDetailPage() {
  const { id = '' } = useParams()
  const detail = useQuery({ queryKey: ['run', id], queryFn: () => fetchRun(id) })

  if (detail.isLoading) return <p>Loading run…</p>
  if (detail.isError) return <p className="error">Run not found.</p>

  return (
    <div>
      <p>
        <Link to="/">← All runs</Link>
      </p>
      {detail.data && (
        <>
          <h1>
            {detail.data.run.repo} · {detail.data.run.branch}{' '}
            <StatusBadge status={detail.data.run.status} />
          </h1>
          <p className="meta">
            {detail.data.run.tool} · {detail.data.run.model} · variant{' '}
            <strong>{detail.data.run.variantName}</strong> · started{' '}
            {new Date(detail.data.run.startedAt).toLocaleString()} · cost{' '}
            {detail.data.run.totalCostUsd == null
              ? '—'
              : `$${detail.data.run.totalCostUsd.toFixed(2)}`} ·{' '}
            {detail.data.run.totalTokens?.toLocaleString() ?? '—'} tokens
          </p>
        </>
      )}

      {detail.data && (
        <ul className="patch-list">
          {detail.data.patches.map((patch) => (
            <li key={patch.id} className="patch">
              <div className="patch-header">
                <span className="patch-path">{patch.filePath}</span>
                <span className="patch-stats">
                  +{patch.linesAdded} −{patch.linesRemoved} · {patch.latencyMs} ms · $
                  {patch.costUsd.toFixed(2)}
                </span>
                {patch.verdict ? (
                  <span className="patch-verdict">
                    <VerdictBadge decision={patch.verdict.decision} />
                    <span className="patch-reviewer">{patch.verdict.reviewer}</span>
                    {patch.verdict.overrideReason && (
                      <span className="patch-override" title={patch.verdict.overrideReason}>
                        overridden
                      </span>
                    )}
                  </span>
                ) : (
                  <span className="patch-verdict">not reviewed</span>
                )}
              </div>
              <pre className="diff">{patch.diffUnified}</pre>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
