// El sitio anterior estaba hecho en Flutter y registraba este service worker.
// Esta versión lo desinstala: borra las copias guardadas y recarga las pestañas abiertas
// para que todos vean el sitio nuevo. Se puede borrar este archivo desde mediados de 2027.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    const claves = await caches.keys();
    await Promise.all(claves.map(k => caches.delete(k)));
    await self.registration.unregister();
    const pestanas = await self.clients.matchAll({ type: 'window' });
    pestanas.forEach(p => p.navigate(p.url));
  })());
});
