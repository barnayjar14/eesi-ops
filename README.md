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
1. Go to https://supabase.com and sign up
2. Click **New Project**
   - Name: `eesi-elevators`
   - Database Password: (save this somewhere safe!)
   - Region: Singapore (AP-SOUTHEAST-1) for best Philippines latency
3. Wait for project to initialize (~2 min)

4. **Run the SQL Schema:**
   - Go to **SQL Editor** (left sidebar)
   - Click **New Query**
   - Copy entire contents of `supabase-schema.sql`
   - Paste and click **Run**

5. **Create Storage Buckets:**
   - Go to **Storage** → **New bucket**
   - Create 3 buckets: `avatars` (Public), `reports` (Private), `signatures` (Private)

6. **Get Your Credentials:**
   - Go to **Settings** → **API**
   - Copy **Project URL** and **anon public** key

7. **Update `index.html`:**
   - Open `index.html`
   - Find `SUPABASE_URL` and `SUPABASE_ANON_KEY` (around line 1050)
   - Replace with your actual credentials
   - Commit and push: `git add . && git commit -m "Configure Supabase" && git push`

### Step 4: ⚠️ CREATE YOUR ADMIN ACCOUNT (CRITICAL)
Before logging in, you must create the admin user in Supabase:
1. In Supabase Dashboard, go to **Authentication** → **Users**
2. Click **Add user** → **Create new user**
3. Email: `barnayjarodel14@gmail.com`
4. Password: `469070`
5. Auto Confirm User: **Checked** ✅
6. Click **Create user**
7. Go to **SQL Editor** and run this to grant admin rights:
```sql
   UPDATE public.profiles 
   SET status = 'approved', designation = 'Admin' 
   WHERE email = 'barnayjarodel14@gmail.com';
```

### Step 5: Deploy to Netlify
1. Go to https://app.netlify.com and sign up
2. Click **Add new site** → **Import an existing project**
3. Choose **GitHub** and select `eesi-elevators`
4. Configure:
   - **Build command:** (leave empty)
   - **Publish directory:** `.`
5. Click **Deploy site**

### Step 6: 🔒 SECURE YOUR ACCOUNT (Post-Deployment)
1. Open your deployed Netlify site
2. The login form is pre-filled with your admin credentials for convenience.
3. **Log in.**
4. Immediately go to **Settings (⋮)** → **Change Password** and set a strong, secure password.
5. Open `index.html` in your code editor, remove the `value="barnayjarodel14@gmail.com"` and `value="469070"` attributes from the login inputs, and push the update to GitHub. *(Leaving passwords in HTML source code is a security risk).*

---

## 🔧 Features
✅ Real Supabase Authentication (No demo data)
✅ Admin approval workflow for new registrations
✅ Members management (Online/Offline/Pending)
✅ Announcements board
✅ Schedule management
✅ Service Reports with photos
✅ PMS Checklist
✅ Daily Time Record (DTR) with signature pad
✅ Notes & Recommendations
✅ Work Sites management
✅ Leave requests
✅ Real-time Chat UI
✅ Live employee locations (Admin only)
✅ Dark mode & Offline detection

---

## 📝 Security Checklist
- [x] Demo data removed
- [x] Row Level Security (RLS) enabled in SQL schema
- [ ] Admin password changed after first login
- [ ] Pre-filled login values removed from `index.html` after setup
- [ ] Supabase project set to Private