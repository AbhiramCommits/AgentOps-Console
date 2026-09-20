import { NavLink, Route, Routes } from 'react-router-dom'
import DashboardPage from './pages/DashboardPage'
import RunDetailPage from './pages/RunDetailPage'
import VariantsPage from './pages/VariantsPage'

export default function App() {
  return (
    <div className="app">
      <header className="topbar">
        <NavLink to="/" className="brand">
          AgentOps Console
        </NavLink>
        <nav>
          <NavLink to="/" end>
            Dashboard
          </NavLink>
          <NavLink to="/variants">Variants</NavLink>
        </nav>
      </header>
      <main>
        <Routes>
          <Route path="/" element={<DashboardPage />} />
          <Route path="/runs/:id" element={<RunDetailPage />} />
          <Route path="/variants" element={<VariantsPage />} />
        </Routes>
      </main>
    </div>
  )
}
