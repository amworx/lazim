import { useStore } from './store'
import { t } from './i18n'

export function Circles() {
  const lang = useStore(s => s.lang)
  const circles = useStore(s => s.circles)
  const members = useStore(s => s.members)
  const needs = useStore(s => s.needs)
  const setScreen = useStore(s => s.setScreen)
  const showToast = useStore(s => s.showToast)

  return (
    <div className="scroll-body">
      <div className="sub-head">
        <button className="back" onClick={() => setScreen('home')}>←</button>
        <h2>{t.circles[lang]}</h2>
      </div>
      <p className="screen-sub">
        {lang === 'ar' ? 'مجموعات من الناس يتشاركون الحاجات والطلبات مع بعض.' : 'Groups of people who share needs with each other.'}
      </p>
      {circles.map(c => {
        const open = needs.filter(n => n.circleId === c.id && n.status === 'open').length
        const urgent = needs.filter(n => n.circleId === c.id && n.status === 'open' && n.priority === 'now').length
        return (
          <div key={c.id} className="circle-card">
            <div className="cc-head">
              <div className="cc-emoji" style={{ background: '#fff0f3' }}>{c.emoji}</div>
              <div>
                <div className="cc-name">{lang === 'ar' ? c.name : c.nameEn}</div>
                <div className="cc-meta">
                  {c.memberIds.length} {t.members[lang]} · {open} {t.openCount[lang]}
                </div>
              </div>
              {urgent > 0 && (
                <span className="cc-open" style={{ background: '#fff0f3', color: '#d6336c' }}>
                  {lang === 'ar' ? `${['', '١', '٢', '٣', '٤', '٥'][urgent] ?? urgent} عاجلة` : `${urgent} urgent`}
                </span>
              )}
            </div>
            <div className="cc-face-row">
              {c.memberIds.map(id => {
                const m = members.find(x => x.id === id)
                if (!m) return null
                const label = (lang === 'ar' ? m.name : m.nameEn)[0]
                return <div key={id} className={`cc-face ${m.color}`}>{label}</div>
              })}
              <div className="share-mini">
                <button className="wa" onClick={() => showToast(`✓ WhatsApp`)}>💬</button>
                <button className="tg" onClick={() => showToast(`✓ Telegram`)}>✈️</button>
                <button style={{ background: 'var(--amber)' }} onClick={() => showToast(lang === 'ar' ? 'رمز QR' : 'QR code')}>▦</button>
              </div>
            </div>
          </div>
        )
      })}
      <div className="cc-invite" onClick={() => showToast(lang === 'ar' ? 'رابط دعوة جاهز 🔗' : 'Invite link ready 🔗')}>
        {t.createCircle[lang]}
      </div>
    </div>
  )
}
