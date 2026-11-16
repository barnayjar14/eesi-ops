-- ============================================
-- EESI ELEVATORS - Supabase Database Schema
-- Run this in Supabase SQL Editor
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. PROFILES TABLE (extends auth.users)
-- ============================================
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  id_number TEXT,
  address TEXT,
  team TEXT,
  contact TEXT,
  area TEXT CHECK (area IN ('Visayas', 'Luzon', 'Mindanao')),
  designation TEXT CHECK (designation IN ('Technician', 'Selective Representative', 'Admin')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  avatar_url TEXT,
  cover_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 2. SITES TABLE
-- ============================================
CREATE TABLE public.sites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  address TEXT,
  area TEXT CHECK (area IN ('Visayas', 'Luzon', 'Mindanao')),
  city TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  status TEXT DEFAULT 'active',
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 3. SCHEDULES TABLE
-- ============================================
CREATE TABLE public.schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  region TEXT NOT NULL,
  job_site TEXT NOT NULL,
  site_id UUID REFERENCES public.sites(id),
  schedule_date DATE NOT NULL,
  priority TEXT DEFAULT 'Normal' CHECK (priority IN ('Normal', 'High', 'Urgent')),
  time_in TIME,
  time_out TIME,
  notes TEXT,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 4. SCHEDULE_PERSONNEL (many-to-many)
-- ============================================
CREATE TABLE public.schedule_personnel (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  schedule_id UUID REFERENCES public.schedules(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  UNIQUE(schedule_id, user_id)
);

-- ============================================
-- 5. SERVICE REPORTS
-- ============================================
CREATE TABLE public.service_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  site_id UUID REFERENCES public.sites(id),
  report_date DATE NOT NULL,
  title TEXT NOT NULL,
  details TEXT,
  equipment_type TEXT CHECK (equipment_type IN ('Elevator', 'Escalator / Moving walkway')),
  submitted_by UUID REFERENCES public.profiles(id),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 6. REPORT PHOTOS
-- ============================================
CREATE TABLE public.report_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  report_id UUID REFERENCES public.service_reports(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 7. DELIVERY REPORTS
-- ============================================
CREATE TABLE public.delivery_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  site_id UUID REFERENCES public.sites(id),
  report_date DATE NOT NULL,
  items JSONB,
  delivered_by UUID REFERENCES public.profiles(id),
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 8. PMS CHECKLISTS
-- ============================================
CREATE TABLE public.pms_checklists (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  site_id UUID REFERENCES public.sites(id),
  checklist_date DATE NOT NULL,
  items JSONB NOT NULL, -- Array of {label, checked}
  completed_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 9. DTR (Daily Time Record)
-- ============================================
CREATE TABLE public.dtr_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  entry_date DATE NOT NULL,
  work_location TEXT,
  work_description TEXT,
  time_in TIME,
  time_out TIME,
  overtime NUMERIC DEFAULT 0,
  signature_url TEXT,
  approved_by UUID REFERENCES public.profiles(id),
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 10. NOTES & RECOMMENDATIONS
-- ============================================
CREATE TABLE public.notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.recommendations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  site_id UUID REFERENCES public.sites(id),
  condition TEXT CHECK (condition IN ('Good', 'Fair', 'Needs Replacement')),
  part TEXT,
  reason TEXT,
  specific_location TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 11. ANNOUNCEMENTS
-- ============================================
CREATE TABLE public.announcements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  author_id UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 12. LEAVE REQUESTS
-- ============================================
CREATE TABLE public.leave_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  leave_type TEXT CHECK (leave_type IN ('Sick leave', 'Emergency leave', 'Vacation leave')),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  reason TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 13. CHAT MESSAGES
-- ============================================
CREATE TABLE public.conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  is_group BOOLEAN DEFAULT FALSE,
  group_name TEXT,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.conversation_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  UNIQUE(conversation_id, user_id)
);

CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES public.profiles(id),
  content TEXT NOT NULL,
  reply_to UUID REFERENCES public.messages(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 14. NOTIFICATIONS
-- ============================================
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT,
  icon TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 15. LIVE LOCATIONS
-- ============================================
CREATE TABLE public.user_locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dtr_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Profiles: users can read approved profiles, update own
CREATE POLICY "Public profiles are viewable" ON public.profiles FOR SELECT USING (status = 'approved');
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Sites: all approved users can view
CREATE POLICY "Sites viewable by approved users" ON public.sites FOR SELECT USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND status = 'approved'));
CREATE POLICY "Admins can manage sites" ON public.sites FOR ALL USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND designation = 'Admin'));

-- Service Reports
CREATE POLICY "Users can view reports" ON public.service_reports FOR SELECT USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND status = 'approved'));
CREATE POLICY "Users can create reports" ON public.service_reports FOR INSERT WITH CHECK (auth.uid() = submitted_by);

-- DTR
CREATE POLICY "Users can view own DTR" ON public.dtr_entries FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can create own DTR" ON public.dtr_entries FOR INSERT WITH CHECK (user_id = auth.uid());

-- Notes & Recs
CREATE POLICY "Users manage own notes" ON public.notes FOR ALL USING (user_id = auth.uid());
CREATE POLICY "Users manage own recs" ON public.recommendations FOR ALL USING (user_id = auth.uid());

-- Announcements: all can view, admins can create
CREATE POLICY "Announcements viewable" ON public.announcements FOR SELECT USING (true);
CREATE POLICY "Admins post announcements" ON public.announcements FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND designation = 'Admin'));

-- Leave
CREATE POLICY "Users view own leave" ON public.leave_requests FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users create own leave" ON public.leave_requests FOR INSERT WITH CHECK (user_id = auth.uid());

-- Messages: members of conversation
CREATE POLICY "Members view messages" ON public.messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.conversation_members WHERE conversation_id = messages.conversation_id AND user_id = auth.uid())
);
CREATE POLICY "Members send messages" ON public.messages FOR INSERT WITH CHECK (sender_id = auth.uid());

-- Notifications
CREATE POLICY "Users view own notifications" ON public.notifications FOR SELECT USING (user_id = auth.uid());

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.email
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ============================================
-- STORAGE BUCKETS (create via Supabase Dashboard)
-- ============================================
-- Create these buckets in Supabase > Storage:
-- 1. "avatars" - public, for profile pictures
-- 2. "reports" - private, for report photos
-- 3. "signatures" - private, for DTR signatures

-- ============================================
-- SEED DATA (optional demo data)
-- ============================================
-- Insert via Supabase dashboard after creating admin user