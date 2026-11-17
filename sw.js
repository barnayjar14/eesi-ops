// EESI Ops service worker: background push, notification tap routing, reply from notification.
// Keep this file in the same folder as EESI-Ops-FieldBlue.html on the HTTPS site.

const DB_NAME = "eesi-push";
const ICON = "./icons/icon-192.png";

self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", event => event.waitUntil(self.clients.claim()));

function kvGet(key) {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, 1);
    req.onupgradeneeded = () => req.result.createObjectStore("kv");
    req.onerror = () => reject(req.error);
    req.onsuccess = () => {
      const tx = req.result.transaction("kv", "readonly");
      const get = tx.objectStore("kv").get(key);
      get.onsuccess = () => resolve(get.result);
      get.onerror = () => reject(get.error);
    };
  });
}

function notify(title, body, threadId) {
  return self.registration.showNotification(title, {
    body, icon: ICON, badge: ICON, tag: "status-" + (threadId || "app"),
    data: { threadId: threadId || null, url: "./" }
  });
}

self.addEventListener("push", event => {
  let data = {};
  try { data = event.data ? event.data.json() : {}; }
  catch (e) { data = { title: "EESI Ops", body: event.data ? event.data.text() : "" }; }

  event.waitUntil((async () => {
    const wins = await self.clients.matchAll({ type: "window", includeUncontrolled: true });
    if (wins.some(c => c.visibilityState === "visible")) return;

    const actions = data.threadId
      ? [{ action: "reply", type: "text", title: "Reply", placeholder: "Type a reply" }, { action: "open", title: "Open" }]
      : [{ action: "open", title: "Open" }];

    await self.registration.showNotification(data.title || "EESI Ops", {
      body: data.body || "", icon: ICON, badge: ICON,
      tag: data.tag || ("thread-" + (data.threadId || "app")), renotify: true,
      vibrate: [200, 100, 200],
      data: { threadId: data.threadId || null, url: data.url || "./" },
      actions
    });
  })());
});

async function sendReply(threadId, text) {
  const body = String(text || "").trim();
  if (!body) return;
  const session = await kvGet("session").catch(() => null);
  if (!session || !session.token) {
    return notify("Reply not sent", "Open EESI Ops and sign in to reply.", threadId);
  }
  try {
    const res = await fetch(session.url + "/rest/v1/messages", {
      method: "POST",
      headers: {
        apikey: session.key,
        Authorization: "Bearer " + session.token,
        "Content-Type": "application/json",
        Prefer: "return=minimal"
      },
      body: JSON.stringify({
        thread_id: threadId, user_id: session.userId,
        sender_name: session.name || "User", body
      })
    });
    if (!res.ok) {
      return notify("Reply not sent", "Your sign-in has expired. Open EESI Ops to reply.", threadId);
    }
    return notify("Reply sent", body.slice(0, 120), threadId);
  } catch (e) {
    return notify("Reply not sent", "No connection. Open EESI Ops to reply.", threadId);
  }
}

async function openApp(threadId, url) {
  const target = threadId ? "./?thread=" + encodeURIComponent(threadId) : (url || "./");
  const wins = await self.clients.matchAll({ type: "window", includeUncontrolled: true });
  const win = wins.find(c => c.url.startsWith(self.registration.scope));
  if (win) {
    await win.focus();
    if (threadId) win.postMessage({ type: "open-thread", threadId });
    return;
  }
  return self.clients.openWindow(new URL(target, self.registration.scope).href);
}

self.addEventListener("notificationclick", event => {
  const note = event.notification;
  const data = note.data || {};
  note.close();

  if (event.action === "reply" && event.reply && data.threadId) {
    event.waitUntil(sendReply(data.threadId, event.reply));
    return;
  }
  event.waitUntil(openApp(data.threadId, data.url));
});
