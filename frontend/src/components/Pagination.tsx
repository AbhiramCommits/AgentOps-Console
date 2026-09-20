import styles from './Pagination.module.css'

interface PaginationProps {
  page: number
  totalPages: number
  totalElements: number
  onPageChange: (page: number) => void
}

export default function Pagination({ page, totalPages, totalElements, onPageChange }: PaginationProps) {
  const total = Math.max(totalPages, 1)
  return (
    <nav className={styles.pagination} aria-label="Runs pagination">
      <span className={styles.count}>
        {totalElements.toLocaleString()} run{totalElements === 1 ? '' : 's'}
      </span>
      <button
        type="button"
        className={styles.button}
        onClick={() => onPageChange(page - 1)}
        disabled={page <= 0}
        aria-label="Previous page"
      >
        <span aria-hidden="true">‹</span>
      </button>
      <span className={styles.status} aria-live="polite">
        Page {page + 1} of {total}
      </span>
      <button
        type="button"
        className={styles.button}
        onClick={() => onPageChange(page + 1)}
        disabled={page + 1 >= total}
        aria-label="Next page"
      >
        <span aria-hidden="true">›</span>
      </button>
    </nav>
  )
}
