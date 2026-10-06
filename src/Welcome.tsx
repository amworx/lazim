import { useState } from 'react'
import { useStore } from './store'
import { t } from './i18n'

const SLIDES = ['feature1', 'feature2', 'feature3'] as const

export function Welcome({ onStart }: { onStart: () => void }) {
  const lang = useStore(s => s.lang)
  const setLang = useStore(s => s.setLang)
  const [slide, setSlide] = useState(0)

  const next = () => (slide < SLIDES.length - 1 ? setSlide(slide + 1) : onStart())

  return (
    <div className="phone">
      <div className="app welcome-app">
        <div className="statusbar"><span>٩:٤١</span><span>📶 ᯤ 🔋</span></div>

        <div className="welcome-top">
          <span className="welcome-brand">لازم <em>Lazim</em></span>
          <button className="skip-btn" onClick={onStart}>{t.skip[lang]}</button>
        </div>

        {/* hero: the product itself — needs orbiting a person */}
        <div className="welcome-hero">
          <div className="wh-stage">
            <div className="wh-ring" />
            <div className="wh-core">🙂</div>
            <div className="wh-need n1" style={{ '--d': '0s' } as React.CSSProperties}>🛒<i /></div>
            <div className="wh-need n2" style={{ '--d': '.5s' } as React.CSSProperties}>💊<i /></div>
            <div className="wh-need n3" style={{ '--d': '1s' } as React.CSSProperties}>🎁<i /></div>
            <div className="wh-face f1">👩</div>
            <div className="wh-face f2">🧑</div>
            <div className="wh-check">✅</div>
          </div>
        </div>

        {/* slides */}
        <div className="welcome-slides">
          <div className="ws-track" style={{ transform: `translateX(${lang === 'ar' ? '' : '-'}${slide * 100}%)`, flexDirection: lang === 'ar' ? 'row' : 'row-reverse' }}>
            {SLIDES.map((s, i) => (
              <div key={s} className={`ws-slide${i === slide ? ' current' : ''}`}>
                <h2>{t[`${s}Title` as const][lang]}</h2>
                <p>{t[`${s}Sub` as const][lang]}</p>
              </div>
            ))}
          </div>
        </div>

        <div className="welcome-dots">
          {SLIDES.map((_, i) => (
            <button key={i} className={i === slide ? 'on' : ''} onClick={() => setSlide(i)} aria-label={`slide ${i + 1}`} />
          ))}
        </div>

        <div className="welcome-actions">
          <button className="start-btn" onClick={next}>
            {slide < SLIDES.length - 1 ? t.next[lang] : t.start[lang]}
          </button>
          <button className="lang-mini" onClick={() => setLang(lang === 'ar' ? 'en' : 'ar')}>
            {lang === 'ar' ? 'English' : 'العربية'}
          </button>
        </div>
      </div>
    </div>
  )
}
