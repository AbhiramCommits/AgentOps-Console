import type { RunStatus } from '../api/client'

const LABELS: Record<RunStatus, string> = {
  RUNNING: 'Running',
  SUCCEEDED: 'Succeeded',
  FAILED: 'Failed',
}

export default function StatusBadge({ status }: { status: RunStatus }) {
  return (
    <span className={`status-badge status-${status.toLowerCase()}`}>{LABELS[status]}</span>
  )
}

export function VerdictBadge({ decision }: { decision: 'ACCEPTED' | 'REJECTED' }) {
  return (
    <span className={`verdict-badge verdict-${decision.toLowerCase()}`}>{decision}</span>
  )
}
