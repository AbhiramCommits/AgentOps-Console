import type { RunStatus, VerdictDecision } from '../api/types'
import styles from './StatusBadge.module.css'

const RUN_LABELS: Record<RunStatus, string> = {
  RUNNING: 'Running',
  SUCCEEDED: 'Succeeded',
  FAILED: 'Failed',
}

export default function StatusBadge({ status }: { status: RunStatus }) {
  return (
    <span className={`${styles.badge} ${styles[`status-${status.toLowerCase()}`]}`}>
      {RUN_LABELS[status]}
    </span>
  )
}

export function VerdictBadge({ decision }: { decision: VerdictDecision }) {
  return (
    <span className={`${styles.badge} ${styles[`verdict-${decision.toLowerCase()}`]}`}>
      {decision === 'ACCEPTED' ? 'Accepted' : 'Rejected'}
    </span>
  )
}
