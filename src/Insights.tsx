import { useStore } from './store'
import { t } from './i18n'

const BARS = [40, 60, 35, 80, 55, 90, 70]
const DAYS_AR = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح']
const DAYS_EN = ['M', 'T', 'W', 'T', 'F', 'S', 'S']

export function Insights() {
  const lang = useStore(s => s.lang)
  const needs = useStore(s => s.needs)
  const setScreen = useStore(s => s.setScreen)

  const resolved = needs.filter(n => n.status !== 'open').length
  const pct = needs.length ? Math.round((resolved / needs.length) * 100) : 87

  return (
    <div className="scroll-body">
      <div className="sub-head">
        <button className="back" onClick={() => setScreen('home')}>←</button>
        <h2>{t.insights[lang]}</h2>
      </div>
      <div className="stat-grid">
        <div className="stat stat-hero">
          <b>{lang === 'ar' ? `${pct}٪` : `${pct}%`}</b>
          <span>{t.resolvedThisMonth[lang]}</span>
          <div className="bar-chart">
            {BARS.map((h, i) => (
              <div key={i} className="bar" style={{ height: `${h}%` }}>
                <i style={{ height: '100%' }} />
                <span>{lang === 'ar' ? DAYS_AR[i] : DAYS_EN[i]}</span>
              </div>
            ))}
          </div>
        </div>
        <div className="stat"><b>{lang === 'ar' ? '٢٣' : '23'}</b><span>{t.resolvedCount[lang]}</span><span className="trend up">↑ ١٢٪</span></div>
        <div className="stat"><b>٤.٢{lang === 'ar' ? 'ي' : 'd'}</b><span>{t.avgTime[lang]}</span></div>
        <div className="stat"><b>{lang === 'ar' ? 'سارة' : 'Sara'}</b><span>{t.helpedMost[lang]}</span></div>
        <div className="stat"><b>🛒</b><span>{t.topCategory[lang]}</span></div>
      </div>
    </div>
  )
}
