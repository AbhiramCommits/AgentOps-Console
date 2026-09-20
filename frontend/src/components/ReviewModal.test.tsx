import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ReviewModal from './ReviewModal'

// jsdom does not implement <dialog> showModal/close; stub them for the suite.
beforeAll(() => {
  HTMLDialogElement.prototype.showModal = function showModal() {
    this.open = true
  }
  HTMLDialogElement.prototype.close = function close() {
    this.open = false
    this.dispatchEvent(new Event('close'))
  }
})

describe('ReviewModal', () => {
  it('disables submit until a non-blank reason is entered', async () => {
    const user = userEvent.setup()
    const onSubmit = vi.fn()
    render(
      <ReviewModal
        open
        patchPath="src/main.go"
        isPending={false}
        serverError={null}
        onClose={() => undefined}
        onSubmit={onSubmit}
      />,
    )

    const submit = screen.getByRole('button', { name: 'Reject patch' })
    expect(submit).toBeDisabled()

    await user.type(screen.getByLabelText(/Override reason/), '   ')
    expect(submit).toBeDisabled()

    await user.type(screen.getByLabelText(/Override reason/), 'causes a flaky test')
    expect(submit).toBeEnabled()

    await user.click(submit)
    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith('causes a flaky test')
    })
  })

  it('shows the patch path and trims the submitted reason', async () => {
    const user = userEvent.setup()
    const onSubmit = vi.fn()
    render(
      <ReviewModal
        open
        patchPath="src/services/checkout.ts"
        isPending={false}
        serverError={null}
        onClose={() => undefined}
        onSubmit={onSubmit}
      />,
    )

    expect(screen.getByText('src/services/checkout.ts')).toBeInTheDocument()

    await user.type(screen.getByLabelText(/Override reason/), '  flaky test  ')
    await user.click(screen.getByRole('button', { name: 'Reject patch' }))
    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith('flaky test')
    })
  })

  it('renders a server error and blocks submission while pending', async () => {
    const user = userEvent.setup()
    const onSubmit = vi.fn()
    render(
      <ReviewModal
        open
        patchPath="src/main.go"
        isPending
        serverError="The change violates a database constraint"
        onClose={() => undefined}
        onSubmit={onSubmit}
      />,
    )

    expect(screen.getByRole('alert')).toHaveTextContent('database constraint')
    await user.type(screen.getByLabelText(/Override reason/), 'some reason')
    const submit = screen.getByRole('button', { name: 'Rejecting…' })
    expect(submit).toBeDisabled()
    await user.click(submit)
    expect(onSubmit).not.toHaveBeenCalled()
  })
})
