import { render, screen } from '@testing-library/react'
import StatusBadge, { VerdictBadge } from './StatusBadge'

describe('StatusBadge', () => {
  it('renders a succeeded badge', () => {
    render(<StatusBadge status="SUCCEEDED" />)
    expect(screen.getByText('Succeeded')).toBeInTheDocument()
  })

  it('renders a running badge', () => {
    render(<StatusBadge status="RUNNING" />)
    expect(screen.getByText('Running')).toBeInTheDocument()
  })

  it('renders a failed badge', () => {
    render(<StatusBadge status="FAILED" />)
    expect(screen.getByText('Failed')).toBeInTheDocument()
  })
})

describe('VerdictBadge', () => {
  it('renders an accepted verdict', () => {
    render(<VerdictBadge decision="ACCEPTED" />)
    expect(screen.getByText('Accepted')).toBeInTheDocument()
  })

  it('renders a rejected verdict', () => {
    render(<VerdictBadge decision="REJECTED" />)
    expect(screen.getByText('Rejected')).toBeInTheDocument()
  })
})
