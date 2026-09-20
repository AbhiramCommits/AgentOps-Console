import { useQuery } from '@tanstack/react-query'
import { fetchVariants } from '../api/client'

export default function VariantsPage() {
  const variants = useQuery({ queryKey: ['variants'], queryFn: fetchVariants })

  if (variants.isLoading) return <p>Loading variants…</p>
  if (variants.isError) return <p className="error">Failed to load variants.</p>

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
          {(variants.data ?? []).map(({ variant, stats }) => {
            const total = stats?.totalVerdicts ?? 0
            const accepted = stats?.accepted ?? 0
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
