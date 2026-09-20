import { render, screen } from '@testing-library/react'
import DiffView from './DiffView'

const SAMPLE = `diff --git a/src/services/checkout.ts b/src/services/checkout.ts
index ab12cd34..ef56ab78 100644
--- a/src/services/checkout.ts
+++ b/src/services/checkout.ts
@@ -1,3 +1,4 @@
  const total = items.reduce((sum, item) => sum + item.price, 0)
-const fee = total * 0.02
+const fee = total * 0.015
+const tax = total * 0.08
  return total + fee
`

describe('DiffView', () => {
  it('renders a side-by-side table with before/after headers', () => {
    render(<DiffView diff={SAMPLE} />)
    expect(screen.getByText('Before')).toBeInTheDocument()
    expect(screen.getByText('After')).toBeInTheDocument()
  })

  it('marks added lines with a plus gutter and removed lines with a minus gutter', () => {
    render(<DiffView diff={SAMPLE} />)

    const plusGutters = screen.getAllByText('+')
    const minusGutters = screen.getAllByText('-')
    expect(plusGutters.length).toBeGreaterThanOrEqual(2)
    expect(minusGutters.length).toBeGreaterThanOrEqual(1)

    expect(screen.getByText('const fee = total * 0.02')).toBeInTheDocument()
    expect(screen.getByText('const fee = total * 0.015')).toBeInTheDocument()
    expect(screen.getByText('const tax = total * 0.08')).toBeInTheDocument()
  })

  it('renders the hunk header row spanning both columns', () => {
    render(<DiffView diff={SAMPLE} />)
    expect(screen.getByText('@@ -1,3 +1,4 @@')).toBeInTheDocument()
  })
})
