import { useMemo } from 'react'
import styles from './LineChart.module.css'

export interface ChartPoint {
  x: number
  y: number
}

export interface ChartSeries {
  id: string
  label: string
  color: string
  points: ChartPoint[]
}

interface LineChartProps {
  title: string
  series: ChartSeries[]
  yFormat: (value: number) => string
  xFormat: (value: number) => string
  yMin?: number
}

const WIDTH = 800
const HEIGHT = 280
const PAD = { top: 14, right: 14, bottom: 34, left: 62 }

function ticks(min: number, max: number, count: number): number[] {
  if (min === max) return [min]
  return Array.from({ length: count }, (_, i) => min + ((max - min) * i) / (count - 1))
}

export default function LineChart({ title, series, yFormat, xFormat, yMin = 0 }: LineChartProps) {
  const geometry = useMemo(() => {
    const allPoints = series.flatMap((s) => s.points)
    const xMin = Math.min(...allPoints.map((p) => p.x))
    const xMax = Math.max(...allPoints.map((p) => p.x))
    const yMax = Math.max(yMin, ...allPoints.map((p) => p.y))
    const innerWidth = WIDTH - PAD.left - PAD.right
    const innerHeight = HEIGHT - PAD.top - PAD.bottom
    const x = (value: number) => PAD.left + ((value - xMin) / (xMax - xMin || 1)) * innerWidth
    const y = (value: number) => PAD.top + innerHeight - ((value - yMin) / (yMax - yMin || 1)) * innerHeight
    const xTicks = ticks(xMin, xMax, 5)
    const yTicks = ticks(yMin, yMax, 5)
    return { x, y, xTicks, yTicks, innerHeight, yMax }
  }, [series, yMin])

  return (
    <figure className={styles.figure}>
      <figcaption className={styles.caption}>{title}</figcaption>
      <svg
        className={styles.svg}
        viewBox={`0 0 ${WIDTH} ${HEIGHT}`}
        role="img"
        aria-label={title}
        preserveAspectRatio="xMidYMid meet"
      >
        {geometry.yTicks.map((tick) => (
          <g key={`y-${tick}`}>
            <line
              x1={PAD.left}
              x2={WIDTH - PAD.right}
              y1={geometry.y(tick)}
              y2={geometry.y(tick)}
              className={styles.gridLine}
            />
            <text x={PAD.left - 8} y={geometry.y(tick) + 4} textAnchor="end" className={styles.axisLabel}>
              {yFormat(tick)}
            </text>
          </g>
        ))}
        {geometry.xTicks.map((tick) => (
          <text
            key={`x-${tick}`}
            x={geometry.x(tick)}
            y={HEIGHT - 10}
            textAnchor="middle"
            className={styles.axisLabel}
          >
            {xFormat(tick)}
          </text>
        ))}
        {series.map((s) => (
          <polyline
            key={s.id}
            className={styles.line}
            fill="none"
            stroke={s.color}
            strokeWidth={2}
            points={s.points.map((p) => `${geometry.x(p.x)},${geometry.y(p.y)}`).join(' ')}
          />
        ))}
      </svg>
      <div className={styles.legend}>
        {series.map((s) => (
          <span key={s.id} className={styles.legendItem}>
            <span className={styles.swatch} style={{ backgroundColor: s.color }} aria-hidden="true" />
            {s.label}
          </span>
        ))}
      </div>
    </figure>
  )
}
