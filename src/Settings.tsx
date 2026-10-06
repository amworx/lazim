import { useState } from 'react'
import { useStore } from './store'
import { t } from './i18n'
import { useAuth } from './hooks/useAuth'

export function Settings() {
  const lang = useStore(s => s.lang)
  const setLang = useStore(s => s.setLang)
  const setScreen = useStore(s => s.setScreen)
  const showToast = useStore(s => s.showToast)
  const { user, logout } = useAuth()

  const [alerts, setAlerts] = useState(true)
  const [quiet, setQuiet] = useState(true)
  const [upd, setUpd] = useState<'idle' | 'checking' | 'downloading' | 'installed'>('idle')

  const updText = () => {
    if (upd === 'checking') return t.checking[lang]
    if (upd === 'downloading') return t.downloading[lang]
    if (upd === 'installed') return t.installed[lang]
    return t.version[lang]
  }

  const checkUpdate = () => {
    if (upd !== 'idle') return
    setUpd('checking')
    setTimeout(() => setUpd('downloading'), 700)
    setTimeout(() => { setUpd('installed'); showToast(lang === 'ar' ? 'تم تثبيت التحديث ✓' : 'Update installed ✓') }, 1800)
  }

  const shareApp = async () => {
    const link = 'https://lazim.app'
    if (navigator.share) {
      try { await navigator.share({ title: 'Lazim لازم', text: t.tagline[lang], url: link }) } catch { /* user cancelled */ }
    } else {
      navigator.clipboard?.writeText(link).catch(() => {})
      showToast(t.shareAppToast[lang])
    }
  }

  return (
    <div className="scroll-body">
      <div className="sub-head">
        <button className="back" onClick={() => setScreen('home')}>←</button>
        <h2>{t.settings[lang]}</h2>
      </div>
      <div className="set-profile">
        <div className="pav">{user?.initial ?? 'ل'}</div>
        <div style={{ flex: 1 }}>
          <b>{user?.name}</b>
          <span>{user?.email} · {t.signedInGoogle[lang]}</span>
        </div>
        <button className="signout-btn" onClick={logout}>
          {lang === 'ar' ? 'خروج' : 'Sign out'}
        </button>
      </div>

      <div className="set-title">{lang === 'ar' ? 'المظهر والتنبيهات' : 'Appearance & alerts'}</div>
      <div className="set-group">
        <div className="set-row" onClick={() => setLang(lang === 'ar' ? 'en' : 'ar')}>
          <div className="ic" style={{ background: '#eef3ff' }}>🌐</div>
          <div className="tx"><b>{t.appLanguage[lang]}</b><span>{t.arabicDefault[lang]}</span></div>
          <span className="val">{lang === 'ar' ? 'العربية ›' : 'English ›'}</span>
        </div>
        <div className="set-divider" />
        <div className="set-row" onClick={() => setAlerts(v => !v)}>
          <div className="ic" style={{ background: '#fff0f3' }}>🔔</div>
          <div className="tx"><b>{t.pushAlerts[lang]}</b><span>{t.pushAlertsSub[lang]}</span></div>
          <div className={`switch${alerts ? ' on' : ''}`} />
        </div>
        <div className="set-divider" />
        <div className="set-row" onClick={() => setQuiet(v => !v)}>
          <div className="ic" style={{ background: '#eafaf1' }}>🌙</div>
          <div className="tx"><b>{t.quietHours[lang]}</b><span>{t.quietHoursSub[lang]}</span></div>
          <div className={`switch${quiet ? ' on' : ''}`} />
        </div>
      </div>

      <div className="set-title">{t.circles[lang]}</div>
      <div className="set-group">
        <div className="set-row" onClick={() => setScreen('circles')}>
          <div className="ic" style={{ background: '#f4f0ff' }}>🫂</div>
          <div className="tx"><b>{t.manageCircles[lang]}</b><span>{lang === 'ar' ? 'العائلة، فريق العمل' : 'Family, Work team'}</span></div>
          <span className="chev">{lang === 'ar' ? '‹' : '›'}</span>
        </div>
        <div className="set-divider" />
        <div className="set-row" onClick={() => showToast(lang === 'ar' ? 'من هم يشارك بحاجاته معك' : 'Privacy controls')}>
          <div className="ic" style={{ background: '#eafaf1' }}>🔐</div>
          <div className="tx"><b>{t.privacyCircle[lang]}</b><span>{t.whoSeesWhat[lang]}</span></div>
          <span className="chev">{lang === 'ar' ? '‹' : '›'}</span>
        </div>
      </div>

      <div className="set-title">{lang === 'ar' ? 'التطبيق' : 'App'}</div>
      <div className="set-group">
        <div className="set-row" onClick={checkUpdate}>
          <div className="ic" style={{ background: '#faf0d7' }}>⬇️</div>
          <div className="tx"><b>{t.checkUpdates[lang]}</b><span>{updText()}</span></div>
          <span className="chev">⌁</span>
        </div>
        <div className="set-divider" />
        <div className="set-row" onClick={shareApp}>
          <div className="ic" style={{ background: '#fdeee9' }}>📤</div>
          <div className="tx"><b>{t.shareApp[lang]}</b><span>{t.shareAppSub[lang]}</span></div>
          <span className="chev">{lang === 'ar' ? '‹' : '›'}</span>
        </div>
      </div>

      <div className="about-card">
        <div className="logo">لازم <em>Lazim</em></div>
        <p>{t.tagline[lang]}</p>
      </div>
    </div>
  )
}
