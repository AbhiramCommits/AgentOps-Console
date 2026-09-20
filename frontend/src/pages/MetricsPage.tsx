import { useQuery } from '@tanstack/react-query'
import { fetchAcceptanceMetrics, fetchCostLatencyMetrics } from '../api/client'
import type { AcceptanceBucket, CostLatencyBucket } from '../api/types'
import LineChart from '../components/LineChart'
import type { ChartSeries } from '../components/LineChart'
import { formatDateShort, formatLatency, formatPercent, formatTime } from '../lib/format'
import styles from './MetricsPage.module.css'

const POLL_INTERVAL_MS = 15_000

const CHART_COLORS = ['#2563eb', '#dc2626', '#059669', '#d97706', '#7c3aed', '#db2777', '#0891b2', '#65a30d']

function buildSeries<T extends { variantId: string; variantName: string; bucketStart: string }>(
  buckets: T[],
  yOf: (bucket: T) => number,
): ChartSeries[] {
  const byVariant = new Map<string, { name: string; buckets: T[] }>()
  for (const bucket of buckets) {
    const entry = byVariant.get(bucket.variantId)
    if (entry) entry.buckets.push(bucket)
    else byVariant.set(bucket.variantId, { name: bucket.variantName, buckets: [bucket] })
  }
  const series: ChartSeries[] = []
  let index = 0
  for (const [variantId, entry] of [...byVariant.entries()].sort(([a], [b]) => a.localeCompare(b))) {
    series.push({
      id: variantId,
      label: entry.name,
      color: CHART_COLORS[index % CHART_COLORS.length],
      points: entry.buckets
        .sort((a, b) => a.bucketStart.localeCompare(b.bucketStart))
        .map((bucket) => ({ x: new Date(bucket.bucketStart).getTime(), y: yOf(bucket) })),
    })
    index += 1
  }
  return series
}

export default function MetricsPage() {
  const acceptance = useQuery({
    queryKey: ['metrics', 'acceptance', 'day', 'live'],
    queryFn: () => fetchAcceptanceMetrics('day'),
    refetchInterval: POLL_INTERVAL_MS,
  })
  const costLatency = useQuery({
    queryKey: ['metrics', 'cost-latency', 'day', 'live'],
    queryFn: () => fetchCostLatencyMetrics('day'),
    refetchInterval: POLL_INTERVAL_MS,
  })

  const lastUpdated = Math.max(acceptance.dataUpdatedAt, costLatency.dataUpdatedAt)
  const isRefreshing = acceptance.isFetching || costLatency.isFetching

  const acceptanceSeries = buildSeries<AcceptanceBucket>(acceptance.data ?? [], (bucket) => bucket.acceptanceRate)
  const costSeries = buildSeries<CostLatencyBucket>(costLatency.data ?? [], (bucket) => bucket.totalCostUsd)
  const latencySeries = buildSeries<CostLatencyBucket>(costLatency.data ?? [], (bucket) => bucket.p50LatencyMs)

  return (
    <div>
      <div className={styles.header}>
        <h1>Metrics</h1>
        <p className={styles.updated} aria-live="polite">
          {isRefreshing ? 'Updating…' : 'Updated'}{' '}
          {lastUpdated === 0 ? '' : formatTime(lastUpdated)}
        </p>
      </div>

      {acceptance.isPending && <p>Loading metrics…</p>}
      {acceptance.isError && <p className={styles.error}>Failed to load metrics.</p>}

      {acceptance.data && acceptanceSeries.length > 0 && (
        <div className={styles.chartGrid}>
          <LineChart
            title="Acceptance rate per day"
            series={acceptanceSeries}
            yFormat={(value) => formatPercent(value)}
            xFormat={(ms) => formatDateShort(new Date(ms).toISOString())}
            yMin={0}
          />
          {costSeries.length > 0 && (
            <LineChart
              title="Cost per day"
              series={costSeries}
              yFormat={(value) => `$${value.toFixed(0)}`}
              xFormat={(ms) => formatDateShort(new Date(ms).toISOString())}
              yMin={0}
            />
          )}
          {latencySeries.length > 0 && (
            <LineChart
              title="Median patch latency per day"
              series={latencySeries}
              yFormat={(value) => formatLatency(value)}
              xFormat={(ms) => formatDateShort(new Date(ms).toISOString())}
              yMin={0}
            />
          )}
        </div>
      )}
    </div>
  )
}
