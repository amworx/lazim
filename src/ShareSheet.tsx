import { useState } from 'react'
import { useStore, type Need } from './store'
import { t } from './i18n'

export function ShareSheet({ need, onClose }: { need: Need | null; onClose: () => void }) {
  const lang = useStore(s => s.lang)
  const showToast = useStore(s => s.showToast)
  const circles = useStore(s => s.circles)
  const members = useStore(s => s.members)
  const [target, setTarget] = useState<string>('family')

  if (!need) return null

  const circle = circles.find(c => c.id === need.circleId)
  const sendTargets = [
    { id: 'family', label: lang === 'ar' ? circle?.name ?? 'العائلة' : circle?.nameEn ?? 'Family' },
    ...members
      .filter(m => m.id !== 'me' && circle?.memberIds.includes(m.id))
      .map(m => ({ id: m.id, label: lang === 'ar' ? m.name : m.nameEn })),
  ]

  const send = (app: string) => {
    const text = `${need.emoji} ${need.title}`
    if (app === 'copy') {
      navigator.clipboard?.writeText(text).catch(() => {})
      showToast(t.copied[lang])
    } else {
      showToast(`“${need.title}” ${t.sentVia[lang]} ${app} ✓`)
    }
    onClose()
  }

  return (
    <div className="sheet-backdrop open" onClick={e => { if (e.target === e.currentTarget) onClose() }}>
      <div className="sheet">
        <div className="sheet-handle" />
        <h3>{t.shareNeed[lang]}: {need.title} 📤</h3>
        <div className="share-row">
          <div className="share-app" onClick={() => send('WhatsApp')}><div className="sa-ic wa">💬</div><span>WhatsApp</span></div>
          <div className="share-app" onClick={() => send('Telegram')}><div className="sa-ic tg">✈️</div><span>Telegram</span></div>
          <div className="share-app" onClick={() => send('SMS')}><div className="sa-ic" style={{ background: 'var(--brand2)' }}>✉️</div><span>{lang === 'ar' ? 'رسالة' : 'SMS'}</span></div>
          <div className="share-app" onClick={() => send('copy')}><div className="sa-ic cp">🔗</div><span>{lang === 'ar' ? 'نسخ النص' : 'Copy text'}</span></div>
        </div>
        <div className="composer-row" style={{ marginBottom: 0 }}>
          <span className="row-label">{t.sendTo[lang]}</span>
          {sendTargets.map(tg => (
            <button key={tg.id} className={`seg${target === tg.id ? ' on' : ''}`} onClick={() => setTarget(tg.id)}>
              {tg.label}
            </button>
          ))}
        </div>
      </div>
    </div>
  )
}
