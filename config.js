// Do not commit real keys publicly. Use environment injection on Netlify.
window.EESI_CONFIG = {
  SUPABASE_URL: "https://YOUR-PROJECT.supabase.co",
  SUPABASE_ANON_KEY: "YOUR_PUBLIC_ANON_KEY",
  VAPID_PUBLIC_KEY: "" // optional, for web push
};