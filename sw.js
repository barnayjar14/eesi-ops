const CACHE = 'eesi-v1';
const ASSETS = [
  '/','/index.html','/styles.css','/app.js','/config.js',
  '/manifest.webmanifest','/icons/icon-192.png','/icons/icon-512.png'
];
self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  e.respondWith(
    caches.match(e.request).then(hit => hit || fetch(e.request).then(res => {
      if (res.ok && new URL(e.request.url).origin === location.origin) {
        const copy = res.clone();
        caches.open(CACHE).then(c => c.put(e.request, copy));
      }
      return res;
    }).catch(() => caches.match('/index.html')))
  );
});
self.addEventListener('push', e => {
  const data = e.data?.json?.() || {};
  self.registration.showNotification(data.title || 'EESI', {
    body: data.body || 'New notification',
    icon: '/icons/icon-192.png',
    data: { url: data.url || '/' }
  });
});
self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(clients.openWindow(e.notification.data.url || '/'));
});