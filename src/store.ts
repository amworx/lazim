import { create } from 'zustand'
import type { Lang } from './i18n'

export interface LazimUser {
  uid: string
  name: string
  email: string
  initial: string
  demo: boolean
}

export type Priority = 'now' | 'soon' | 'later'
export type NeedStatus = 'open' | 'done' | 'postponed' | 'not_needed' | 'handed_off'

export interface Need {
  id: string
  emoji: string
  title: string
  priority: Priority
  circleId: string
  ownerId: string
  createdAt: number
  status: NeedStatus
  x: number // orbit position, px in world space
  y: number
}

export interface Member {
  id: string
  name: string
  nameEn: string
  color: string
  angle: number
  radius: number
}

export interface Circle {
  id: string
  name: string
  nameEn: string
  emoji: string
  memberIds: string[]
}

export type Screen = 'home' | 'circles' | 'insights' | 'settings'

interface LazimState {
  lang: Lang
  screen: Screen
  user: LazimUser | null
  needs: Need[]
  members: Member[]
  circles: Circle[]
  activeCircle: string
  toast: string | null
  // actions
  setLang: (l: Lang) => void
  setScreen: (s: Screen) => void
  setUser: (u: LazimUser | null) => void
  addNeed: (title: string, emoji: string, priority: Priority, circleId: string) => void
  resolveNeed: (id: string, status: NeedStatus) => void
  setActiveCircle: (id: string) => void
  showToast: (msg: string) => void
  clearToast: () => void
}

const seedMembers: Member[] = [
  { id: 'sara', name: 'سارة', nameEn: 'Sara', color: 'm1', angle: -35, radius: 195 },
  { id: 'omar', name: 'عمر', nameEn: 'Omar', color: 'm2', angle: 200, radius: 165 },
  { id: 'mom', name: 'ماما', nameEn: 'Mom', color: 'm3', angle: 60, radius: 150 },
  { id: 'dad', name: 'بابا', nameEn: 'Dad', color: 'm4', angle: 100, radius: 185 },
]

const seedCircles: Circle[] = [
  { id: 'family', name: 'العائلة', nameEn: 'Family', emoji: '👨‍👩‍👧', memberIds: ['me', 'sara', 'omar', 'mom', 'dad'] },
  { id: 'work', name: 'فريق العمل', nameEn: 'Work team', emoji: '💼', memberIds: ['me', 'omar'] },
]

let seq = 0
const uid = () => `n${Date.now().toString(36)}${(seq++).toString(36)}`

const polar = (angleDeg: number, radius: number) => ({
  x: Math.cos((angleDeg * Math.PI) / 180) * radius,
  y: Math.sin((angleDeg * Math.PI) / 180) * radius,
})

const seedNeeds: Need[] = [
  { id: 'n1', emoji: '🛒', title: 'حليب الشوفان', priority: 'now', circleId: 'family', ownerId: 'me', createdAt: Date.now() - 2 * 3600e3, status: 'open', ...polar(200, 208) },
  { id: 'n2', emoji: '💊', title: 'تعبئة وصفة تاتا', priority: 'now', circleId: 'family', ownerId: 'sara', createdAt: Date.now() - 5 * 3600e3, status: 'open', ...polar(75, 175) },
  { id: 'n3', emoji: '🎁', title: 'هدية لينا', priority: 'soon', circleId: 'family', ownerId: 'me', createdAt: Date.now() - 26 * 3600e3, status: 'open', ...polar(160, 172) },
  { id: 'n4', emoji: '🧹', title: 'تنظيف الكراج', priority: 'later', circleId: 'family', ownerId: 'omar', createdAt: Date.now() - 3 * 24 * 3600e3, status: 'open', ...polar(35, 225) },
  { id: 'n5', emoji: '📦', title: 'تسليم الشحنة', priority: 'soon', circleId: 'work', ownerId: 'omar', createdAt: Date.now() - 8 * 3600e3, status: 'open', ...polar(280, 160) },
]

export const useStore = create<LazimState>((set, get) => ({
  lang: 'ar',
  screen: 'home',
  user: null,
  needs: seedNeeds,
  members: seedMembers,
  circles: seedCircles,
  activeCircle: 'all',
  toast: null,

  setLang: l => {
    set({ lang: l })
    document.documentElement.setAttribute('dir', l === 'ar' ? 'rtl' : 'ltr')
    document.documentElement.setAttribute('lang', l)
  },
  setScreen: s => set({ screen: s }),
  setUser: u => set({ user: u }),
  setActiveCircle: id => set({ activeCircle: id }),

  addNeed: (title, emoji, priority, circleId) => {
    const n: Need = {
      id: uid(), emoji, title, priority, circleId,
      ownerId: 'me', createdAt: Date.now(), status: 'open',
      ...polar(Math.random() * 360, 140 + Math.random() * 90),
    }
    set({ needs: [...get().needs, n] })
  },

  resolveNeed: (id, status) => set({ needs: get().needs.map(n => (n.id === id ? { ...n, status } : n)) }),

  showToast: msg => set({ toast: msg }),
  clearToast: () => set({ toast: null }),
}))

// helper: needs visible in current filter
export const visibleNeeds = (s: LazimState) =>
  s.activeCircle === 'all' ? s.needs.filter(n => n.status === 'open') : s.needs.filter(n => n.status === 'open' && n.circleId === s.activeCircle)
