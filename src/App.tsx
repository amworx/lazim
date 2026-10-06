import { useEffect, useState } from 'react'
import { useStore, visibleNeeds, type Need } from './store'
import { t, type TKey } from './i18n'
import { Orbit } from './Orbit'
import { Composer } from './Composer'
import { ShareSheet } from './ShareSheet'
import { Circles } from './Circles'
import { Insights } from './Insights'
import { Settings } from './Settings'
import { SignIn } from './SignIn'
import { Welcome } from './Welcome'
import { useAuth } from './hooks/useAuth'
import './app.css'

export function App() {
  const lang = useStore(s => s.lang)
  const { user, error, loginWithGoogle, logout, demoMode } = useAuth()
  const screen = useStore(s => s.screen)
  const setScreen = useStore(s => s.setScreen)
  const needs = useStore(visibleNeeds)
  const activeCircle = useStore(s => s.activeCircle)
  const setActiveCircle = useStore(s => s.setActiveCircle)
  const members = useStore(s => s.members)
  const toast = useStore(s => s.toast)
  const clearToast = useStore(s => s.clearToast)

  const [composerOpen, setComposerOpen] = useState(false)
  const [shareNeed, setShareNeed] = useState<Need | null>(null)
  const [stage, setStage] = useState<'welcome' | 'signin'>(() =>
    localStorage.getItem('lazim.welcomed') === '1' ? 'signin' : 'welcome',
  )

  const tr = (k: TKey) => t[k][lang]

  useEffect(() => {
    if (!toast) return
    const tm = setTimeout(clearToast, 1700)
    return () => clearTimeout(tm)
  }, [toast, clearToast])

  if (!user) {
    if (stage === 'welcome') {
      return (
        <Welcome
          onStart={() => {
            localStorage.setItem('lazim.welcomed', '1')
            setStage('signin')
          }}
        />
      )
    }
    return <SignIn onGoogle={loginWithGoogle} demoMode={demoMode} />
  }

  const openCount = needs.length

  return (
    <div className="phone">
      <div className="app">
        <div className="statusbar"><span>٩:٤١</span><span>📶 ᯤ 🔋</span></div>

        <header className="orbit-top">
          <div>
            <div className="date">{tr('today')}، ٦ أكتوبر</div>
            <h2>{tr('glanceTitle')}</h2>
          </div>
          <div className="orbit-top-actions">
            <button className="top-btn" onClick={() => setScreen('settings')}>⚙️</button>
          </div>
        </header>
        {user.demo && (
          <div className="demo-banner">
            {lang === 'ar' ? 'وضع تجريبي' : 'Demo mode'}
            <button onClick={logout}>{lang === 'ar' ? 'خروج' : 'Sign out'}</button>
          </div>
        )}

        {screen === 'home' && (
          <>
            <Orbit
              needs={needs}
              members={members.filter(m => activeCircle === 'all' || m.id !== 'me')}
              openCount={openCount}
              onShare={setShareNeed}
            />
            <div className="zoom-hud">
              <button onClick={() => window.dispatchEvent(new CustomEvent('lazim:zoom', { detail: 1.25 }))}>＋</button>
              <button onClick={() => window.dispatchEvent(new CustomEvent('lazim:zoom', { detail: 0.8 }))}>−</button>
              <button onClick={() => window.dispatchEvent(new CustomEvent('lazim:reset'))}>⌂</button>
            </div>
            <nav className="orbit-nav">
              <button
                className={activeCircle === 'all' ? 'active' : ''}
                onClick={() => setActiveCircle('all')}
              >
                {tr('today')}
              </button>
              <button
                className={activeCircle === 'family' ? 'active' : ''}
                onClick={() => setActiveCircle('family')}
              >
                {tr('circles')}
              </button>
              <button
                className={activeCircle === 'me' ? 'active' : ''}
                onClick={() => setActiveCircle('me')}
              >
                {tr('me')}
              </button>
            </nav>
            <button className="orbit-fab" onClick={() => setComposerOpen(true)}>＋</button>
          </>
        )}

        {screen === 'circles' && <Circles />}
        {screen === 'insights' && <Insights />}
        {screen === 'settings' && <Settings />}

        <Composer open={composerOpen} onClose={() => setComposerOpen(false)} />
        <ShareSheet need={shareNeed} onClose={() => setShareNeed(null)} />

        {error && <div className="toast show" style={{ background: 'var(--danger)' }}>{error}</div>}

        {toast && <div className="toast show">{toast}</div>}
      </div>
    </div>
  )
}
