import { useEffect, useRef, useState } from 'react'
import type { FormEvent } from 'react'
import styles from './ReviewModal.module.css'

interface ReviewModalProps {
  open: boolean
  patchPath: string
  isPending: boolean
  serverError: string | null
  onClose: () => void
  onSubmit: (overrideReason: string) => void
}

export default function ReviewModal({
  open,
  patchPath,
  isPending,
  serverError,
  onClose,
  onSubmit,
}: ReviewModalProps) {
  const dialogRef = useRef<HTMLDialogElement>(null)
  const [reason, setReason] = useState('')

  useEffect(() => {
    const dialog = dialogRef.current
    if (!dialog) return
    if (open && !dialog.open) {
      setReason('')
      dialog.showModal()
    } else if (!open && dialog.open) {
      dialog.close()
    }
  }, [open])

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (reason.trim() === '' || isPending) return
    onSubmit(reason.trim())
  }

  return (
    <dialog
      ref={dialogRef}
      className={styles.dialog}
      aria-labelledby="reject-dialog-title"
      onCancel={(event) => {
        event.preventDefault()
        if (!isPending) onClose()
      }}
      onClick={(event) => {
        if (event.target === dialogRef.current && !isPending) onClose()
      }}
    >
      <form onSubmit={handleSubmit} className={styles.form}>
        <h2 id="reject-dialog-title" className={styles.title}>
          Reject patch
        </h2>
        <p className={styles.path}>{patchPath}</p>

        <label htmlFor="override-reason" className={styles.label}>
          Override reason <span className={styles.required}>(required)</span>
        </label>
        <textarea
          id="override-reason"
          className={styles.textarea}
          rows={4}
          value={reason}
          onChange={(event) => setReason(event.target.value)}
          placeholder="Why is this patch being rejected?"
          autoFocus
          maxLength={1000}
          aria-describedby={serverError ? 'reject-error' : undefined}
        />
        <div className={styles.counter} aria-hidden="true">
          {reason.length}/1000
        </div>

        {serverError && (
          <p id="reject-error" className={styles.error} role="alert">
            {serverError}
          </p>
        )}

        <div className={styles.actions}>
          <button type="button" className={styles.secondary} onClick={onClose} disabled={isPending}>
            Cancel
          </button>
          <button type="submit" className={styles.danger} disabled={reason.trim() === '' || isPending}>
            {isPending ? 'Rejecting…' : 'Reject patch'}
          </button>
        </div>
      </form>
    </dialog>
  )
}
