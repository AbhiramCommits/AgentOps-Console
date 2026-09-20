export function formatUsd(value: number | null | undefined): string {
  if (value == null) return '—'
  return `$${value.toFixed(2)}`
}

export function formatPercent(ratio: number, digits = 0): string {
  return `${(ratio * 100).toFixed(digits)}%`
}

export function formatNumber(value: number): string {
  return value.toLocaleString()
}

export function formatDate(iso: string | null | undefined): string {
  if (!iso) return '—'
  return new Date(iso).toLocaleString()
}

export function formatDateShort(iso: string): string {
  return new Date(iso).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
}

export function formatDuration(startedAt: string, finishedAt: string | null): string {
  const start = new Date(startedAt).getTime()
  const end = finishedAt ? new Date(finishedAt).getTime() : Date.now()
  const minutes = Math.max(0, Math.round((end - start) / 60000))
  if (minutes < 1) return '<1m'
  if (minutes < 60) return `${minutes}m`
  const hours = Math.floor(minutes / 60)
  const rest = minutes % 60
  return rest === 0 ? `${hours}h` : `${hours}h ${rest}m`
}

export function formatLatency(ms: number): string {
  if (ms < 1000) return `${Math.round(ms)} ms`
  return `${(ms / 1000).toFixed(1)} s`
}

export function formatTime(ts: number): string {
  return new Date(ts).toLocaleTimeString()
}
