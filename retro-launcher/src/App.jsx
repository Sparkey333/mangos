import React, { useEffect } from 'react'
import { Routes, Route, useLocation } from 'react-router-dom'
import { AnimatePresence } from 'framer-motion'
import Home from './pages/Home'
import Library from './pages/Library'
import GameDetail from './pages/GameDetail'
import Settings from './pages/Settings'
import Admin from './pages/Admin'
import EmuPlayer from './pages/EmuPlayer'
import { useRotationLock } from './utils/rotation'
import { AdminFlagProvider } from './components/AdminPanel/FeatureFlags'
import './styles/theme.css'

export default function App() {
  const location = useLocation()
  useRotationLock()

  return (
    <AdminFlagProvider>
      <AnimatePresence mode="wait" initial={false}>
        <Routes location={location} key={location.pathname}>
          <Route path="/" element={<Home />} />
          <Route path="/library" element={<Library />} />
          <Route path="/game/:id" element={<GameDetail />} />
          <Route path="/play/:id" element={<EmuPlayer />} />
          <Route path="/settings" element={<Settings />} />
          <Route path="/admin" element={<Admin />} />
        </Routes>
      </AnimatePresence>
    </AdminFlagProvider>
  )
}
