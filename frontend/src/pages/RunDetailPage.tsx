import { useQuery } from '@tanstack/react-query'
import { Link, useParams } from 'react-router-dom'
import { fetchRun, fetchRunPatches } from '../api/client'
import StatusBadge, { VerdictBadge } from '../components/StatusBadge'

export default function RunDetailPage() {
  const { id = '' } = useParams()
  const run = useQuery({ queryKey: ['run', id], queryFn: () => fetchRun(id) })
  const patches = useQuery({ queryKey: ['run-patches', id], queryFn: () => fetchRunPatches(id) })

  if (run.isLoading) return <p>Loading run…</p>
  if (run.isError) return <p className="error">Run not found.</p>

  return (
    <div>
      <p>
        <Link to="/">← All runs</Link>
      </p>
      {run.data && (
        <>
          <h1>
            {run.data.repo} · {run.data.branch} <StatusBadge status={run.data.status} />
          </h1>
          <p className="meta">
            {run.data.tool} · {run.data.model} · variant <strong>{run.data.variantName}</strong> ·{' '}
            started {new Date(run.data.startedAt).toLocaleString()} · cost{' '}
            {run.data.totalCostUsd == null ? '—' : `$${run.data.totalCostUsd.toFixed(2)}`} ·{' '}
            {run.data.totalTokens?.toLocaleString() ?? '—'} tokens
          </p>
        </>
      )}

      {patches.isLoading && <p>Loading patches…</p>}
      {patches.data && (
        <ul className="patch-list">
          {patches.data.map((patch) => (
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
