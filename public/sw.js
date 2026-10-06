/* Lazim service worker — tiny offline shell */
const CACHE = 'lazim-v1'

self.addEventListener('install', e => {
  self.skipWaiting()
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(['./', './index.html'])))
})

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim()),
  )
})

self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return
  const url = new URL(e.request.url)
  if (url.origin !== location.origin) return

  // navigations: network-first so updates land, offline fallback to shell
  if (e.request.mode === 'navigate') {
    e.respondWith(
      fetch(e.request)
        .then(r => { caches.open(CACHE).then(c => c.put('./', r.clone())); return r })
        .catch(() => caches.match('./')),
    )
    return
  }

  // static assets: cache-first
  e.respondWith(
    caches.match(e.request).then(hit =>
      hit ||
      fetch(e.request).then(r => {
        if (r.ok) caches.open(CACHE).then(c => c.put(e.request, r.clone()))
        return r
      }),
    ),
  )
})
