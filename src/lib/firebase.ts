import { initializeApp, type FirebaseApp } from 'firebase/app'
import { getAuth, GoogleAuthProvider, type Auth } from 'firebase/auth'
import { getFirestore, type Firestore } from 'firebase/firestore'

/**
 * Firebase is initialized lazily and only when real credentials are present
 * in the environment (.env.local). Until then the app runs in demo mode.
 */
const cfg = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY as string | undefined,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN as string | undefined,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID as string | undefined,
}

export const firebaseReady = Boolean(cfg.apiKey && cfg.authDomain && cfg.projectId)

let app: FirebaseApp | null = null
let auth: Auth | null = null
let db: Firestore | null = null
export const googleProvider = new GoogleAuthProvider()

if (firebaseReady) {
  app = initializeApp(cfg)
  auth = getAuth(app)
  db = getFirestore(app)
}

export function getFirebase() {
  return { app, auth, db }
}
