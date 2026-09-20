import styles from './Skeleton.module.css'

export function SkeletonTable({ rows, columns }: { rows: number; columns: number }) {
  return (
    <div className={styles.wrapper} aria-busy="true" aria-label="Loading runs">
      {Array.from({ length: rows }, (_, row) => (
        <div key={row} className={styles.row}>
          {Array.from({ length: columns }, (_, col) => (
            <div key={col} className={styles.cell} />
          ))}
        </div>
      ))}
    </div>
  )
}

export function SkeletonCards({ count }: { count: number }) {
  return (
    <div className={styles.cards} aria-busy="true" aria-label="Loading metrics">
      {Array.from({ length: count }, (_, i) => (
        <div key={i} className={styles.card}>
          <div className={styles.cardValue} />
          <div className={styles.cardLabel} />
        </div>
      ))}
    </div>
  )
}
