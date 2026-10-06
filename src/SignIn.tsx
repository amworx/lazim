import { useStore } from './store'
import { t } from './i18n'

export function SignIn({ onGoogle, demoMode }: { onGoogle: () => void; demoMode: boolean }) {
  const lang = useStore(s => s.lang)

  return (
    <div className="phone">
      <div className="app signin-app">
        <div className="statusbar"><span>٩:٤١</span><span>📶 ᯤ 🔋</span></div>
        <div className="signin-body">

          {/* advanced orbit hero (Orbiting-Circles style): needs + family
              avatars in counter-rotating rings around a glowing core */}
          <div className="si-hero">
            <div className="si-stage">
              <div className="si-glow" />
              <div className="si-orbit" style={{ '--T': '16s' } as React.CSSProperties}>
                <div className="si-path" style={{ '--r': 78 } as React.CSSProperties} />
                {['🛒', '💊', '🎁'].map((e, i) => (
                  <div key={e} className="orb-slot" style={{ '--a': i * 120, '--r': 78, '--T': '16s' } as React.CSSProperties}>
                    <div className="orb-chip">{e}</div>
                  </div>
                ))}
              </div>
              <div className="si-orbit reverse" style={{ '--T': '26s' } as React.CSSProperties}>
                <div className="si-path" style={{ '--r': 116 } as React.CSSProperties} />
                {['س', 'ع', 'م', 'ب'].map((ch, i) => (
                  <div key={ch} className="orb-slot" style={{ '--a': i * 90, '--r': 116, '--T': '26s' } as React.CSSProperties}>
                    <div className={`orb-chip member m${i}`}>{ch}</div>
                  </div>
                ))}
              </div>
              <div className="si-core">
                <span className="core-swirl" />
                <span className="core-shine" />
              </div>
            </div>
            <h1>{t.signInTitle[lang]}</h1>
            <p className="si-sub">{t.signInSub[lang]}</p>
          </div>

          <button className="google-btn" onClick={onGoogle}>
            <svg width="20" height="20" viewBox="0 0 48 48" aria-hidden>
              <path fill="#FFC107" d="M43.6 20.1H42V20H24v8h11.3C33.7 32.7 29.3 36 24 36c-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.9 1.2 8 3l5.7-5.7C34.3 6.1 29.4 4 24 4 13 4 4 13 4 24s9 20 20 20 20-9 20-20c0-1.3-.1-2.6-.4-3.9z"/>
              <path fill="#FF3D00" d="M6.3 14.7l6.6 4.8C14.7 15.1 19 12 24 12c3.1 0 5.9 1.2 8 3l5.7-5.7C34.3 6.1 29.4 4 24 4 16.3 4 9.7 8.3 6.3 14.7z"/>
              <path fill="#4CAF50" d="M24 44c5.2 0 9.9-2 13.4-5.2l-6.2-5.2C29.2 35.1 26.7 36 24 36c-5.3 0-9.7-3.3-11.3-8l-6.5 5C9.6 39.6 16.2 44 24 44z"/>
              <path fill="#1976D2" d="M43.6 20.1H42V20H24v8h11.3c-.8 2.2-2.2 4.1-4.1 5.6l6.2 5.2C36.9 39.2 44 34 44 24c0-1.3-.1-2.6-.4-3.9z"/>
            </svg>
            {t.continueGoogle[lang]}
          </button>

          <p className="signin-hint">{t.signInHint[lang]}</p>

          {demoMode && <div className="demo-note">{t.demoModeNote[lang]}</div>}

          <div className="lang-row">
            <button onClick={() => useStore.getState().setLang(lang === 'ar' ? 'en' : 'ar')}>
              {lang === 'ar' ? 'English' : 'العربية'}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
