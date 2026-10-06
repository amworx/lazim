import { useEffect, useState } from 'react'
import { signInWithPopup, signInWithRedirect, getRedirectResult, onAuthStateChanged, signOut } from 'firebase/auth'
import { getFirebase, googleProvider, firebaseReady } from '../lib/firebase'
import { useStore, type LazimUser } from '../store'

function toLazimUser(u: import('firebase/auth').User): LazimUser {
  return {
    uid: u.uid,
    name: u.displayName ?? (u.email?.split('@')[0] ?? 'User'),
    email: u.email ?? '',
    initial: (u.displayName ?? u.email ?? 'U')[0].toUpperCase(),
    demo: false,
  }
}

export function useAuth() {
  const user = useStore(s => s.user)
  const setUser = useStore(s => s.setUser)
  const [loading, setLoading] = useState(firebaseReady)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!firebaseReady) return
    const { auth } = getFirebase()
    // complete a redirect-based sign-in (fallback path used in webviews)
    getRedirectResult(auth!).catch(() => {/* no redirect pending */})
    const unsub = onAuthStateChanged(auth!, u => {
      setUser(u ? toLazimUser(u) : null)
      setLoading(false)
    })
    return unsub
  }, [setUser])

  const loginWithGoogle = async () => {
    setError(null)
    if (!firebaseReady) {
      // demo mode: fake session so the whole app stays testable
      setUser({
        uid: 'demo',
        name: 'ليلى حسن',
        email: 'layla@gmail.com',
        initial: 'ل',
        demo: true,
      })
      return
    }
    try {
      const { auth } = getFirebase()
      await signInWithPopup(auth!, googleProvider)
    } catch (e) {
      const code = (e as { code?: string })?.code ?? ''
      const msg = e instanceof Error ? e.message : String(e)
      // popups are unreliable inside webviews / embedded browsers —
      // fall back to a full-page redirect, which works everywhere.
      const popupFailures = [
        'auth/popup-blocked',
        'auth/popup-closed-by-user',
        'auth/cancelled-popup-request',
        'auth/operation-not-supported-in-this-environment',
      ]
      if (popupFailures.includes(code)) {
        try {
          const { auth: a } = getFirebase()
          await signInWithRedirect(a!, googleProvider)
        } catch (e2) {
          setError(e2 instanceof Error ? e2.message : String(e2))
        }
        return
      }
      if (code !== 'auth/popup-closed-by-user' && !msg.includes('popup-closed')) setError(msg)
    }
  }

  const logout = async () => {
    if (firebaseReady) {
      const { auth } = getFirebase()
      await signOut(auth!)
    }
    setUser(null)
  }

  return { user, loading, error, loginWithGoogle, logout, demoMode: !firebaseReady }
}
