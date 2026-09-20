import { useQuery } from '@tanstack/react-query'
import { fetchAcceptanceMetrics, fetchVariants } from '../api/client'

export default function VariantsPage() {
  const variants = useQuery({ queryKey: ['variants'], queryFn: fetchVariants })
  const acceptance = useQuery({
    queryKey: ['metrics', 'acceptance', 'week'],
    queryFn: () => fetchAcceptanceMetrics('week'),
  })

  if (variants.isLoading) return <p>Loading variants…</p>
  if (variants.isError) return <p className="error">Failed to load variants.</p>

  const acceptedByVariant = new Map<string, number>()
  const totalByVariant = new Map<string, number>()
  for (const bucket of acceptance.data ?? []) {
    acceptedByVariant.set(bucket.variantId, (acceptedByVariant.get(bucket.variantId) ?? 0) + bucket.accepted)
    totalByVariant.set(bucket.variantId, (totalByVariant.get(bucket.variantId) ?? 0) + bucket.total)
  }

  return (
    <div>
      <h1>Prompt Variants</h1>
      <table className="runs-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Description</th>
            <th>Verdicts</th>
            <th>Accepted</th>
            <th>Acceptance rate</th>
          </tr>
        </thead>
        <tbody>
          {(variants.data ?? []).map((variant) => {
            const total = totalByVariant.get(variant.id) ?? 0
            const accepted = acceptedByVariant.get(variant.id) ?? 0
            return (
              <tr key={variant.id}>
                <td>{variant.name}</td>
                <td>{variant.description}</td>
                <td>{total}</td>
                <td>{accepted}</td>
                <td>{total === 0 ? '—' : `${Math.round((100 * accepted) / total)}%`}</td>
              </tr>
            )
          })}
        </tbody>
      </table>
    </div>
  )
}
