self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", e => e.waitUntil(self.clients.claim()));

self.addEventListener("push", e => {
  const data = e.data ? e.data.json() : {};
  const title = data.title || "EESI Ops";
  const options = {
    body: data.body || "",
    icon: "./icons/icon-192.png",
    badge: "./icons/icon-192.png",
    data: { threadId: data.threadId || null }
  };
  e.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener("notificationclick", e => {
  e.notification.close();
  const threadId = e.notification.data && e.notification.data.threadId;
  e.waitUntil(
    self.clients.matchAll({ type: "window", includeUncontrolled: true }).then(list => {
      for (const c of list) {
        if ("focus" in c) {
          c.focus();
          if (threadId) c.postMessage({ type: "open-thread", threadId });
          return;
        }
      }
      return self.clients.openWindow(threadId ? "./?thread=" + encodeURIComponent(threadId) : "./");
    })
  );
});