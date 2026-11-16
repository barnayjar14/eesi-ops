# 🛗 EESI Elevators Operations Console

Complete operations management app for EESI Elevators Inc.

## 🚀 Deployment Guide

### Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `eesi-elevators`
3. Make it **Private** (company app)
4. Click **Create repository**

### Step 2: Push Code to GitHub

Open terminal in your project folder:

```bash
git init
git add .
git commit -m "Initial commit - EESI Elevators app"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/eesi-elevators.git
git push -u origin main
```

### Step 3: Set Up Supabase (Database)

1. Go to https://supabase.com and sign up (free tier available)
2. Click **New Project**
   - Name: `eesi-elevators`
   - Database Password: (save this somewhere safe!)
   - Region: Choose closest to Philippines (Singapore/AP-SOUTHEAST-1)
3. Wait for project to initialize (~2 min)

4. **Run the SQL Schema:**
   - Go to **SQL Editor** (left sidebar)
   - Click **New Query**
   - Copy entire contents of `supabase-schema.sql`
   - Paste and click **Run**
   - Wait for "Success. No rows returned"

5. **Create Storage Buckets:**
   - Go to **Storage** (left sidebar)
   - Click **New bucket**
   - Create 3 buckets:
     - `avatars` (Public)
     - `reports` (Private)
     - `signatures` (Private)

6. **Get Your Credentials:**
   - Go to **Settings** → **API**
   - Copy:
     - **Project URL** (e.g., `https://xxxxx.supabase.co`)
     - **anon public** key

7. **Update `index.html`:**
   - Open `index.html`
   - Find these lines (around line 1100):
```javascript
     const SUPABASE_URL = 'https://YOUR-PROJECT.supabase.co';
     const SUPABASE_ANON_KEY = 'YOUR-ANON-KEY';
```
   - Replace with your actual credentials
   - Commit and push:
```bash
     git add index.html
     git commit -m "Configure Supabase credentials"
     git push
```

### Step 4: Deploy to Netlify

**Option A: Connect GitHub (Recommended)**

1. Go to https://app.netlify.com and sign up
2. Click **Add new site** → **Import an existing project**
3. Choose **GitHub**
4. Authorize Netlify to access your repo
5. Select `eesi-elevators` repository
6. Configure:
   - **Build command:** (leave empty)
   - **Publish directory:** `.` (just a dot)
7. Click **Deploy site**
8. Wait ~30 seconds → Your site is LIVE! 🎉

**Option B: Drag & Drop**

1. Go to https://app.netlify.com/drop
2. Drag your entire project folder
3. Done!

### Step 5: Custom Domain (Optional)

1. In Netlify dashboard → **Domain settings**
2. Click **Add custom domain**
3. Enter your domain (e.g., `eesi-elevators.com`)
4. Follow DNS instructions

### Step 6: Create First Admin User

1. Open your deployed site
2. Click **Register**
3. Fill in your details
4. Set **Requested designation** = `Admin`
5. In Supabase Dashboard:
   - Go to **Authentication** → **Users**
   - Find your email → Click to edit
   - Or run SQL:
```sql
     UPDATE public.profiles
     SET status = 'approved', designation = 'Admin'
     WHERE email = 'your@email.com';
```

---

## 🔧 Features

✅ Sign In / Register (with admin approval)
✅ Google & Facebook OAuth (configure in Supabase)
✅ Members management (Online/Offline/Pending)
✅ Announcements board
✅ Schedule management
✅ Service Reports with photos
✅ Delivery Reports
✅ PMS Checklist
✅ Daily Time Record (DTR) with signature
✅ Notes & Recommendations
✅ Work Sites management
✅ Leave requests
✅ Real-time Chat
✅ Live employee locations
✅ Notifications
✅ Dark mode
✅ Mobile responsive
✅ Offline detection

---

## 🔐 Security Notes

- Never commit `.env` files
- Use Supabase RLS (already configured)
- Enable 2FA on Supabase dashboard
- Rotate keys if exposed

---

## 📞 Support

For issues, check:
- Supabase logs: Dashboard → Logs
- Netlify logs: Site → Deploys → Deploy log

---

## 📝 Environment Variables (Optional)

Create `.env` file: