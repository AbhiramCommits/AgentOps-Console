import { useMemo } from 'react'
import { parseUnifiedDiff, toSideBySideRows } from '../lib/diff'
import type { DiffLine } from '../lib/diff'
import styles from './DiffView.module.css'

function Gutter({ line }: { line: DiffLine | null }) {
  if (!line) return null
  const sign = line.type === 'added' ? '+' : line.type === 'removed' ? '-' : ' '
  return (
    <>
      <td className={`${styles.gutter} ${styles[line.type]}`} aria-hidden="true">
        {sign}
      </td>
      <td className={`${styles.lineNumber} ${styles[line.type]}`} aria-hidden="true">
        {line.newLine ?? line.oldLine}
      </td>
      <td className={`${styles.text} ${styles[line.type]}`}>
        <span className={styles.lineContent}>{line.text === '' ? '\u00A0' : line.text}</span>
      </td>
    </>
  )
}

function EmptyCell() {
  return <td className={styles.empty} colSpan={3} aria-hidden="true" />
}

export default function DiffView({ diff }: { diff: string }) {
  const rows = useMemo(() => toSideBySideRows(parseUnifiedDiff(diff)), [diff])

  return (
    <div className={styles.scroll}>
      <table className={styles.table}>
        <caption className="sr-only">Side-by-side diff: removed lines on the left, added lines on the right</caption>
        <thead>
          <tr>
            <th className={styles.header} colSpan={3}>
              Before
            </th>
            <th className={styles.header} colSpan={3}>
              After
            </th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row, index) =>
            row.hunkHeader ? (
              <tr key={`h-${index}`} className={styles.hunkRow}>
                <td className={styles.hunkHeader} colSpan={6}>
                  {row.hunkHeader}
                </td>
              </tr>
            ) : (
              <tr key={`l-${index}`}>
                {row.left ? <Gutter line={row.left} /> : <EmptyCell />}
                {row.right ? <Gutter line={row.right} /> : <EmptyCell />}
              </tr>
            ),
          )}
        </tbody>
      </table>
    </div>
  )
}
