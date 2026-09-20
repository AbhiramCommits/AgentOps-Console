import { render } from '@testing-library/react'
import LineChart from './LineChart'
import type { ChartSeries } from './LineChart'

function renderChart(series: ChartSeries[]) {
  const { container } = render(
    <LineChart
      title="Test chart"
      series={series}
      yFormat={(value) => String(value)}
      xFormat={(ms) => new Date(ms).toISOString()}
      yMin={0}
    />,
  )
  return container
}

describe('LineChart', () => {
  it('renders nothing for empty series instead of crashing on NaN ticks', () => {
    // Regression: Math.min/max of an empty point list is +/-Infinity, which
    // used to produce NaN ticks and a RangeError in the date formatter.
    expect(renderChart([]).innerHTML).toBe('')
  })

  it('renders lines, ticks and a legend for real series', () => {
    const series: ChartSeries[] = [
      {
        id: 'v1',
        label: 'baseline-v1',
        color: '#2563eb',
        points: [
          { x: new Date('2026-08-08T00:00:00Z').getTime(), y: 0.4 },
          { x: new Date('2026-08-09T00:00:00Z').getTime(), y: 0.6 },
        ],
      },
    ]
    const container = renderChart(series)
    expect(container.querySelector('polyline')).not.toBeNull()
    expect(container.textContent).toContain('baseline-v1')
  })

  it('renders a single tick when all points share the same x value', () => {
    const series: ChartSeries[] = [
      {
        id: 'v1',
        label: 'single-point',
        color: '#059669',
        points: [{ x: new Date('2026-08-08T00:00:00Z').getTime(), y: 1 }],
      },
    ]
    const container = renderChart(series)
    expect(container.querySelector('polyline')).not.toBeNull()
    expect(container.textContent).toContain('single-point')
  })
})
