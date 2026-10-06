import { useEffect, useRef, useState, useCallback } from 'react'
import { useStore, type Need, type Member } from './store'
import { t } from './i18n'

interface Props {
  needs: Need[]
  members: Member[]
  openCount: number
  onShare: (n: Need) => void
}

export function Orbit({ needs, members, openCount, onShare }: Props) {
  const viewportRef = useRef<HTMLDivElement>(null)
  const worldRef = useRef<HTMLDivElement>(null)
  const lang = useStore(s => s.lang)
  const resolveNeed = useStore(s => s.resolveNeed)
  const showToast = useStore(s => s.showToast)

  // transform state kept in refs to avoid re-render on pan/zoom
  const tf = useRef({ scale: 1, tx: 0, ty: 0 })
  const [menuFor, setMenuFor] = useState<Need | null>(null)
  const menuRef = useRef<HTMLDivElement>(null)

  const apply = useCallback(() => {
    const { scale, tx, ty } = tf.current
    if (worldRef.current)
      worldRef.current.style.transform = `translate(${tx}px, ${ty}px) scale(${scale})`
  }, [])

  const zoomBy = useCallback((f: number, cx?: number, cy?: number) => {
    const vp = viewportRef.current
    if (!vp) return
    const { scale, tx, ty } = tf.current
    const ns = Math.min(2.5, Math.max(0.5, scale * f))
    const k = ns / scale
    const ccx = cx ?? vp.clientWidth / 2
    const ccy = cy ?? vp.clientHeight / 2
    tf.current.tx = ccx - (ccx - tx) * k
    tf.current.ty = ccy - (ccy - ty) * k
    tf.current.scale = ns
    apply()
  }, [apply])

  const reset = useCallback(() => {
    tf.current = { scale: 1, tx: 0, ty: 0 }
    apply()
    showToast(t.reset[useStore.getState().lang])
  }, [apply, showToast])

  // zoom HUD events from App
  useEffect(() => {
    const z = (e: Event) => zoomBy((e as CustomEvent).detail as number)
    window.addEventListener('lazim:zoom', z)
    window.addEventListener('lazim:reset', reset)
    return () => {
      window.removeEventListener('lazim:zoom', z)
      window.removeEventListener('lazim:reset', reset)
    }
  }, [zoomBy, reset])

  // wheel zoom + drag pan + pinch
  useEffect(() => {
    const vp = viewportRef.current
    if (!vp) return
    let panning = false
    let sx = 0, sy = 0
    const pts = new Map<number, PointerEvent>()
    let pinchD0 = 0, pinchS0 = 1

    const onWheel = (e: WheelEvent) => {
      e.preventDefault()
      const r = vp.getBoundingClientRect()
      zoomBy(e.deltaY < 0 ? 1.12 : 0.89, e.clientX - r.left, e.clientY - r.top)
    }
    const onDown = (e: PointerEvent) => {
      if ((e.target as HTMLElement).closest('.need-bubble,.radial-menu')) return
      pts.set(e.pointerId, e)
      if (pts.size === 2) {
        const [a, b] = [...pts.values()]
        pinchD0 = Math.hypot(a.clientX - b.clientX, a.clientY - b.clientY)
        pinchS0 = tf.current.scale
        panning = false
        return
      }
      panning = true
      sx = e.clientX - tf.current.tx; sy = e.clientY - tf.current.ty
      vp.setPointerCapture(e.pointerId)
    }
    const onMove = (e: PointerEvent) => {
      if (pts.has(e.pointerId)) pts.set(e.pointerId, e)
      if (pts.size === 2) {
        const [a, b] = [...pts.values()]
        const d = Math.hypot(a.clientX - b.clientX, a.clientY - b.clientY)
        tf.current.scale = Math.min(2.5, Math.max(0.5, pinchS0 * d / pinchD0))
        apply()
        return
      }
      if (!panning) return
      const nx = e.clientX - sx, ny = e.clientY - sy
      tf.current.tx = nx; tf.current.ty = ny
      apply()
    }
    const onUp = (e: PointerEvent) => { pts.delete(e.pointerId); panning = false }
    vp.addEventListener('wheel', onWheel, { passive: false })
    vp.addEventListener('pointerdown', onDown)
    vp.addEventListener('pointermove', onMove)
    vp.addEventListener('pointerup', onUp)
    vp.addEventListener('pointercancel', onUp)
    return () => {
      vp.removeEventListener('wheel', onWheel)
      vp.removeEventListener('pointerdown', onDown)
      vp.removeEventListener('pointermove', onMove)
      vp.removeEventListener('pointerup', onUp)
      vp.removeEventListener('pointercancel', onUp)
    }
  }, [zoomBy, apply])

  // close radial menu on outside tap
  useEffect(() => {
    if (!menuFor) return
    const h = (e: PointerEvent) => {
      if (!(e.target as HTMLElement).closest('.radial-menu,.need-bubble')) setMenuFor(null)
    }
    document.addEventListener('pointerdown', h)
    return () => document.removeEventListener('pointerdown', h)
  }, [menuFor])

  const bubbleClick = (n: Need) => setMenuFor(m => (m?.id === n.id ? null : n))

  const resolve = (n: Need, status: 'done' | 'postponed') => {
    resolveNeed(n.id, status)
    setMenuFor(null)
    showToast(`“${n.title}” → ${status === 'done' ? t.done[lang] : t.postponed[lang]}`)
  }

  const share = (n: Need) => {
    setMenuFor(null)
    onShare(n)
  }

  return (
    <div className="orbit-viewport" ref={viewportRef}>
      <div className="orbit-world" ref={worldRef}>
        <div className="orbit-ring" />
        <div className="orbit-ring r2" />
        <div className="orbit-center">
          <b>{t.you[lang]}</b>
          <small>{openCount} {t.openNeeds[lang]}</small>
        </div>
        {members.map((m: Member) => {
          const rad = (m.angle * Math.PI) / 180
          const style = {
            left: Math.cos(rad) * m.radius,
            top: Math.sin(rad) * m.radius,
          }
          return (
            <div key={m.id} className={`orbit-member ${m.color}`} style={style}>
              <small>{lang === 'ar' ? m.name : m.nameEn}</small>
              {(lang === 'ar' ? m.name : m.nameEn)[0]}
            </div>
          )
        })}
        {needs.map(n => (
          <div
            key={n.id}
            className={`need-bubble ${n.priority === 'now' ? 'urgent' : ''}`}
            style={{ left: n.x, top: n.y }}
            onClick={() => bubbleClick(n)}
          >
            {n.emoji} <span>{n.title}</span>
          </div>
        ))}
        {menuFor && (
          <div
            className="radial-menu open"
            style={{ left: menuFor.x, top: menuFor.y }}
            ref={menuRef}
          >
            <div className="radial-dot" style={{ left: 0, top: -64 }} onClick={() => resolve(menuFor, 'done')}>✅</div>
            <div className="radial-dot" style={{ left: 58, top: -32 }} onClick={() => resolve(menuFor, 'done')}>🛍️</div>
            <div className="radial-dot" style={{ left: 58, top: 32 }} onClick={() => resolve(menuFor, 'postponed')}>📅</div>
            <div className="radial-dot" style={{ left: 0, top: 64 }} onClick={() => resolve(menuFor, 'done')}>🔁</div>
            <div className="radial-dot" style={{ left: -58, top: 32 }} onClick={() => resolve(menuFor, 'done')}>❌</div>
            <div className="radial-dot" style={{ left: -58, top: -32 }} onClick={() => share(menuFor)}>📤</div>
          </div>
        )}
      </div>
    </div>
  )
}
