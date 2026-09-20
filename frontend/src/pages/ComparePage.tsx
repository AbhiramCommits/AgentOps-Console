import { useQuery } from '@tanstack/react-query'
import { useMemo, useState } from 'react'
import { fetchAcceptanceMetrics, fetchCostLatencyMetrics, fetchVariants } from '../api/client'
import type { AcceptanceBucket, CostLatencyBucket, Variant } from '../api/types'
import { formatLatency, formatPercent, formatUsd } from '../lib/format'
import styles from './ComparePage.module.css'

interface VariantComparison {
  variant: Variant
  acceptanceRate: number
  accepted: number
  totalVerdicts: number
  medianLatencyMs: number
  costPerAcceptedUsd: number
  totalCostUsd: number
}

function aggregate(
  variant: Variant,
  acceptance: AcceptanceBucket[],
  costLatency: CostLatencyBucket[],
): VariantComparison {
  const accBuckets = acceptance.filter((bucket) => bucket.variantId === variant.id)
  const latencyBuckets = costLatency.filter((bucket) => bucket.variantId === variant.id)

  const accepted = accBuckets.reduce((sum, bucket) => sum + bucket.accepted, 0)
  const total = accBuckets.reduce((sum, bucket) => sum + bucket.total, 0)
  const totalCost = latencyBuckets.reduce((sum, bucket) => sum + bucket.totalCostUsd, 0)
  const weightedLatency = latencyBuckets.reduce((sum, bucket) => sum + bucket.p50LatencyMs * bucket.patchCount, 0)
  const patchCount = latencyBuckets.reduce((sum, bucket) => sum + bucket.patchCount, 0)

  return {
    variant,
    acceptanceRate: total === 0 ? 0 : accepted / total,
    accepted,
    totalVerdicts: total,
    medianLatencyMs: patchCount === 0 ? 0 : weightedLatency / patchCount,
    costPerAcceptedUsd: accepted === 0 ? 0 : totalCost / accepted,
    totalCostUsd: totalCost,
  }
}

function Delta({ value, betterWhenLower }: { value: number; betterWhenLower: boolean }) {
  const good = betterWhenLower ? value < 0 : value > 0
  const sign = value > 0 ? '+' : value < 0 ? '' : '±'
  return (
    <span className={value === 0 ? styles.deltaNeutral : good ? styles.deltaGood : styles.deltaBad}>
      {sign}
      {value.toFixed(1)}
    </span>
  )
}

export default function ComparePage() {
  const variants = useQuery({ queryKey: ['variants'], queryFn: fetchVariants })
  const acceptance = useQuery({
    queryKey: ['metrics', 'acceptance', 'week'],
    queryFn: () => fetchAcceptanceMetrics('week'),
  })
  const costLatency = useQuery({
    queryKey: ['metrics', 'cost-latency', 'week'],
    queryFn: () => fetchCostLatencyMetrics('week'),
  })

  const variantList = variants.data ?? []
  const [leftId, setLeftId] = useState('')
  const [rightId, setRightId] = useState('')

  const left = variantList.find((v) => v.id === leftId) ?? variantList[0]
  const right = variantList.filter((v) => v.id !== left?.id).find((v) => v.id === rightId) ??
    variantList.find((v) => v.id !== left?.id)

  const comparison = useMemo(() => {
    if (!left || !right) return null
    return {
      left: aggregate(left, acceptance.data ?? [], costLatency.data ?? []),
      right: aggregate(right, acceptance.data ?? [], costLatency.data ?? []),
    }
  }, [left, right, acceptance.data, costLatency.data])

  if (variants.isLoading) return <p>Loading variants…</p>
  if (variantList.length < 2) return <p>Need at least two prompt variants to compare.</p>

  const rightOptions = variantList.filter((v) => v.id !== left?.id)

  return (
    <div>
      <h1>Compare Prompt Variants</h1>
      <div className={styles.pickers}>
        <label className={styles.picker}>
          <span className={styles.pickerLabel}>Variant A</span>
          <select
            value={left?.id ?? ''}
            onChange={(event) => {
              setLeftId(event.target.value)
              if (event.target.value === right?.id) setRightId('')
            }}
          >
            {variantList.map((variant) => (
              <option key={variant.id} value={variant.id}>
                {variant.name}
              </option>
            ))}
          </select>
        </label>
        <span className={styles.vs} aria-hidden="true">
          vs
        </span>
        <label className={styles.picker}>
          <span className={styles.pickerLabel}>Variant B</span>
          <select value={right?.id ?? ''} onChange={(event) => setRightId(event.target.value)}>
            {rightOptions.map((variant) => (
              <option key={variant.id} value={variant.id}>
                {variant.name}
              </option>
            ))}
          </select>
        </label>
      </div>

      {comparison && (
        <div className={styles.columns}>
          <section className={styles.column} aria-label={`Metrics for ${comparison.left.variant.name}`}>
            <h2 className={styles.columnTitle}>{comparison.left.variant.name}</h2>
            <dl className={styles.stats}>
              <div className={styles.stat}>
                <dt>Acceptance rate</dt>
                <dd>{formatPercent(comparison.left.acceptanceRate, 1)}</dd>
              </div>
              <div className={styles.stat}>
                <dt>Median latency</dt>
                <dd>{formatLatency(comparison.left.medianLatencyMs)}</dd>
              </div>
              <div className={styles.stat}>
                <dt>Cost per accepted patch</dt>
                <dd>{comparison.left.accepted === 0 ? '—' : formatUsd(comparison.left.costPerAcceptedUsd)}</dd>
              </div>
              <div className={styles.stat}>
                <dt>Total cost</dt>
                <dd>{formatUsd(comparison.left.totalCostUsd)}</dd>
              </div>
              <div className={styles.stat}>
                <dt>Verdicts</dt>
                <dd>
                  {comparison.left.accepted} / {comparison.left.totalVerdicts}
                </dd>
              </div>
            </dl>
          </section>

          <div className={styles.deltas} aria-label="Deltas of variant B versus variant A">
            <div className={styles.deltaRow}>
              <span className={styles.deltaLabel}>Acceptance rate</span>
              <Delta
                value={(comparison.right.acceptanceRate - comparison.left.acceptanceRate) * 100}
                betterWhenLower={false}
              />
              <span className={styles.deltaUnit}>pp</span>
            </div>
            <div className={styles.deltaRow}>
              <span className={styles.deltaLabel}>Median latency</span>
              <Delta
                value={
                  comparison.left.medianLatencyMs === 0
                    ? 0
                    : ((comparison.right.medianLatencyMs - comparison.left.medianLatencyMs) /
                        comparison.left.medianLatencyMs) *
                      100
                }
                betterWhenLower
              />
              <span className={styles.deltaUnit}>%</span>
            </div>
            <div className={styles.deltaRow}>
              <span className={styles.deltaLabel}>Cost / accepted</span>
              <Delta
                value={
                  comparison.left.costPerAcceptedUsd === 0
                    ? 0
                    : ((comparison.right.costPerAcceptedUsd - comparison.left.costPerAcceptedUsd) /
                        comparison.left.costPerAcceptedUsd) *
                      100
                }
                betterWhenLower
              />
              <span className={styles.deltaUnit}>%</span>
            </div>
          </div>

          <section className={styles.column} aria-label={`Metrics for ${comparison.right.variant.name}`}>
            <h2 className={styles.columnTitle}>{comparison.right.variant.name}</h2>
            <dl className={styles.stats}>
              <div className={styles.stat}>
                <dt>Acceptance rate</dt>
                <dd>{formatPercent(comparison.right.acceptanceRate, 1)}</dd>
              </div>
              <div className={styles.stat}>
                <dt>Median latency</dt>
                <dd>{formatLatency(comparison.right.medianLatencyMs)}</dd>
              </div>
              <div className={styles.stat}>
                <dt>Cost per accepted patch</dt>
                <dd>{comparison.right.accepted === 0 ? '—' : formatUsd(comparison.right.costPerAcceptedUsd)}</dd>
              </div>
              <div className={styles.stat}>
                <dt>Total cost</dt>
                <dd>{formatUsd(comparison.right.totalCostUsd)}</dd>
              </div>
              <div className={styles.stat}>
                <dt>Verdicts</dt>
                <dd>
                  {comparison.right.accepted} / {comparison.right.totalVerdicts}
                </dd>
              </div>
            </dl>
          </section>
        </div>
      )}
    </div>
  )
}
