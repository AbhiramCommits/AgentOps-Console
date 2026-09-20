import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { amendPatchReview, fetchRun, reviewPatch } from '../api/client'
import type { Patch, RunDetail, Verdict, VerdictDecision } from '../api/types'
import DiffView from '../components/DiffView'
import ReviewModal from '../components/ReviewModal'
import StatusBadge, { VerdictBadge } from '../components/StatusBadge'
import { formatDate, formatLatency, formatUsd } from '../lib/format'
import styles from './RunDetailPage.module.css'

interface ReviewVariables {
  patchId: string
  decision: VerdictDecision
  overrideReason?: string
  hasVerdict: boolean
}

export default function RunDetailPage() {
  const { id = '' } = useParams()
  const queryClient = useQueryClient()
  const [rejectPatch, setRejectPatch] = useState<Patch | null>(null)

  const detail = useQuery({ queryKey: ['run', id], queryFn: () => fetchRun(id), retry: 1 })

  const review = useMutation({
    mutationFn: (variables: ReviewVariables) => {
      const body = { reviewer: 'you', decision: variables.decision, overrideReason: variables.overrideReason }
      return variables.hasVerdict ? amendPatchReview(variables.patchId, body) : reviewPatch(variables.patchId, body)
    },
    onMutate: async (variables): Promise<RunDetail | undefined> => {
      await queryClient.cancelQueries({ queryKey: ['run', id] })
      const snapshot = queryClient.getQueryData<RunDetail>(['run', id])
      if (!snapshot) return undefined
      const optimistic: Verdict = {
        id: 'pending',
        patchId: variables.patchId,
        reviewer: 'you',
        decision: variables.decision,
        overrideReason: variables.overrideReason ?? null,
        decidedAt: new Date().toISOString(),
      }
      queryClient.setQueryData<RunDetail>(['run', id], {
        ...snapshot,
        patches: snapshot.patches.map((patch) =>
          patch.id === variables.patchId ? { ...patch, verdict: optimistic } : patch,
        ),
      })
      return snapshot
    },
    onError: (_error, _variables, context) => {
      if (context) queryClient.setQueryData(['run', id], context)
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['run', id] })
      queryClient.invalidateQueries({ queryKey: ['runs'] })
    },
  })

  if (detail.isLoading) return <p>Loading run…</p>
  if (detail.isError || !detail.data) return <p className={styles.error}>Run not found.</p>

  const { run, patches } = detail.data
  const pendingPatchId = review.isPending ? (review.variables?.patchId ?? null) : null

  function handleDecision(patch: Patch, decision: VerdictDecision) {
    review.mutate({ patchId: patch.id, decision, hasVerdict: patch.verdict != null })
  }

  function handleRejectSubmit(overrideReason: string) {
    if (!rejectPatch) return
    review.mutate(
      { patchId: rejectPatch.id, decision: 'REJECTED', overrideReason, hasVerdict: rejectPatch.verdict != null },
      {
        onSuccess: () => setRejectPatch(null),
      },
    )
  }

  return (
    <div>
      <p>
        <Link to="/">← All runs</Link>
      </p>
      <h1 className={styles.title}>
        {run.repo} · {run.branch} <StatusBadge status={run.status} />
      </h1>
      <p className={styles.meta}>
        {run.tool} · {run.model} · variant <strong>{run.variantName}</strong> · started{' '}
        {formatDate(run.startedAt)} · cost {formatUsd(run.totalCostUsd)} ·{' '}
        {run.totalTokens?.toLocaleString() ?? '—'} tokens
      </p>

      {review.isError && (
        <div className={styles.banner} role="alert">
          Review failed: {(review.error as Error).message}
        </div>
      )}

      <ul className={styles.patchList}>
        {patches.map((patch) => (
          <li key={patch.id} className={styles.patch}>
            <details className={styles.details}>
              <summary
                className={styles.summary}
                onClick={(event) => {
                  if ((event.target as HTMLElement).closest('button')) event.preventDefault()
                }}
              >
                <span className={styles.summaryMain}>
                  <span className={styles.patchPath}>{patch.filePath}</span>
                  <span className={styles.patchStats}>
                    +{patch.linesAdded} −{patch.linesRemoved} · {formatLatency(patch.latencyMs)} ·{' '}
                    {formatUsd(patch.costUsd)}
                  </span>
                </span>
                <span className={styles.summaryAside}>
                  {patch.verdict ? (
                    <span className={styles.verdictInfo}>
                      <VerdictBadge decision={patch.verdict.decision} />
                      <span className={styles.reviewer}>
                        {patch.verdict.reviewer} · {formatDate(patch.verdict.decidedAt)}
                      </span>
                      {patch.verdict.decision === 'REJECTED' && patch.verdict.overrideReason && (
                        <span className={styles.overrideReason} title={patch.verdict.overrideReason}>
                          “{patch.verdict.overrideReason}”
                        </span>
                      )}
                    </span>
                  ) : (
                    <span className={styles.notReviewed}>not reviewed</span>
                  )}
                  <button
                    type="button"
                    className={styles.acceptButton}
                    onClick={() => handleDecision(patch, 'ACCEPTED')}
                    disabled={pendingPatchId === patch.id || patch.verdict?.decision === 'ACCEPTED'}
                    title={patch.verdict?.decision === 'ACCEPTED' ? 'Already accepted' : 'Accept this patch'}
                  >
                    {pendingPatchId === patch.id && patch.verdict?.decision === 'ACCEPTED'
                      ? 'Accepting…'
                      : 'Accept'}
                  </button>
                  <button
                    type="button"
                    className={styles.rejectButton}
                    onClick={() => setRejectPatch(patch)}
                    disabled={pendingPatchId === patch.id || patch.verdict?.decision === 'REJECTED'}
                    title={patch.verdict?.decision === 'REJECTED' ? 'Already rejected' : 'Reject this patch'}
                  >
                    Reject
                  </button>
                </span>
              </summary>
              <DiffView diff={patch.diffUnified} />
            </details>
          </li>
        ))}
      </ul>

      <ReviewModal
        open={rejectPatch != null}
        patchPath={rejectPatch?.filePath ?? ''}
        isPending={review.isPending}
        serverError={review.isError ? (review.error as Error).message : null}
        onClose={() => {
          if (!review.isPending) setRejectPatch(null)
        }}
        onSubmit={handleRejectSubmit}
      />
    </div>
  )
}
