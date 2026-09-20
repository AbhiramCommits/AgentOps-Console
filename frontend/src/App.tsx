import { NavLink, Route, Routes } from 'react-router-dom'
import ComparePage from './pages/ComparePage'
import MetricsPage from './pages/MetricsPage'
import RunDetailPage from './pages/RunDetailPage'
import RunsPage from './pages/RunsPage'
import styles from './App.module.css'

export default function App() {
  return (
    <div className={styles.app}>
      <header className={styles.topbar}>
        <NavLink to="/" className={styles.brand}>
          AgentOps Console
        </NavLink>
        <nav aria-label="Primary" className={styles.nav}>
          <NavLink to="/" end className={({ isActive }) => (isActive ? styles.linkActive : styles.link)}>
            Runs
          </NavLink>
          <NavLink
            to="/compare"
            className={({ isActive }) => (isActive ? styles.linkActive : styles.link)}
          >
            Compare
          </NavLink>
          <NavLink
            to="/metrics"
            className={({ isActive }) => (isActive ? styles.linkActive : styles.link)}
          >
            Metrics
          </NavLink>
        </nav>
      </header>
      <main className={styles.main}>
        <Routes>
          <Route path="/" element={<RunsPage />} />
          <Route path="/runs/:id" element={<RunDetailPage />} />
          <Route path="/compare" element={<ComparePage />} />
          <Route path="/metrics" element={<MetricsPage />} />
        </Routes>
      </main>
    </div>
  )
}
