import { useState } from 'react'
import { useStore, type Priority } from './store'
import { t, type TKey } from './i18n'

export function Composer({ open, onClose }: { open: boolean; onClose: () => void }) {
  const lang = useStore(s => s.lang)
  const addNeed = useStore(s => s.addNeed)
  const showToast = useStore(s => s.showToast)
  const circles = useStore(s => s.circles)

  const [title, setTitle] = useState('')
  const [priority, setPriority] = useState<Priority>('now')
  const [circleId, setCircleId] = useState('family')

  const tr = (k: TKey) => t[k][lang]

  const submit = () => {
    const v = title.trim() || (lang === 'ar' ? 'حاجة جديدة' : 'New need')
    addNeed(v, '✨', priority, circleId)
    setTitle('')
    onClose()
    showToast(`“${v}” ${tr('launched')}`)
  }

  const seg = (on: boolean, hot = false) => `seg${on ? ' on' : ''}${on && hot ? ' hot' : ''}`

  return (
    <div className={`sheet-backdrop${open ? ' open' : ''}`} onClick={e => { if (e.target === e.currentTarget) onClose() }}>
      <div className="sheet">
        <div className="sheet-handle" />
        <h3>{tr('newNeed')}</h3>
        <input
          className="composer-input"
          placeholder={tr('needPlaceholder')}
          value={title}
          onChange={e => setTitle(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && submit()}
        />
        <div className="composer-row">
          <span className="row-label">{tr('priority')}</span>
          <button className={seg(priority === 'now', true)} onClick={() => setPriority('now')}>{tr('now')}</button>
          <button className={seg(priority === 'soon')} onClick={() => setPriority('soon')}>{tr('soon')}</button>
          <button className={seg(priority === 'later')} onClick={() => setPriority('later')}>{tr('sometime')}</button>
        </div>
        <div className="composer-row">
          <span className="row-label">{tr('shareIn')}</span>
          {circles.map(c => (
            <button key={c.id} className={seg(circleId === c.id)} onClick={() => setCircleId(c.id)}>
              {lang === 'ar' ? c.emoji + ' ' + c.name : c.emoji + ' ' + c.nameEn}
            </button>
          ))}
          <button className={seg(circleId === 'me')} onClick={() => setCircleId('me')}>{tr('justMe')}</button>
        </div>
        <button className="composer-btn" onClick={submit}>{tr('launch')}</button>
      </div>
    </div>
  )
}
