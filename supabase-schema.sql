-- EESI Elevators — Supabase schema
create extension if not exists "pgcrypto";

-- ===== Helpers =====
create or replace function public.my_role() returns text language sql stable as $$
  select coalesce((select role from public.profiles where id = auth.uid()), 'technician');
$$;
create or replace function public.is_manager() returns boolean language sql stable as $$
  select public.my_role() in ('admin','manager');
$$;
create or replace function public.is_admin() returns boolean language sql stable as $$
  select public.my_role() = 'admin';
$$;

-- ===== Tables =====
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text, name text, id_no text, address text, team text, phone text,
  area text,
  role text default 'technician' check (role in ('technician','representative','manager','admin')),
  status text default 'pending' check (status in ('pending','approved','rejected')),
  avatar_url text, cover_url text,
  last_seen timestamptz default now(),
  last_lat double precision, last_lng double precision,
  created_at timestamptz default now()
);

create table if not exists public.sites (
  id uuid primary key default gen_random_uuid(),
  name text not null, address text, region text, city text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now()
);

create table if not exists public.units (
  id uuid primary key default gen_random_uuid(),
  site_id uuid references public.sites(id) on delete cascade,
  name text, type text, status text, brand text, serial text, capacity text, notes text,
  region text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now()
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('service','delivery')),
  site_id uuid references public.sites(id) on delete set null,
  date date not null, title text, details text,
  photos jsonb default '[]'::jsonb,
  region text,
  user_id uuid references public.profiles(id) on delete set null,
  user_name text,
  created_at timestamptz default now()
);

create table if not exists public.pms_records (
  id uuid primary key default gen_random_uuid(),
  site_id uuid references public.sites(id) on delete set null,
  date date not null,
  unit_type text check (unit_type in ('elevator','escalator')),
  checklist jsonb default '{}'::jsonb,
  region text,
  user_id uuid references public.profiles(id) on delete set null,
  user_name text,
  created_at timestamptz default now()
);

create table if not exists public.dtr_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  user_name text,
  date date not null,
  location text, job text, time_in time, time_out time,
  hours numeric(6,2),
  overtime_approved boolean default false,
  created_at timestamptz default now()
);

create table if not exists public.dtr_signatures (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  date date not null,
  signature_url text,
  created_at timestamptz default now(),
  unique(user_id, date)
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text, body text,
  user_id uuid references public.profiles(id) on delete set null,
  user_name text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.schedules (
  id uuid primary key default gen_random_uuid(),
  region text, title text, date date,
  priority text default 'Normal',
  time_in time, time_out time, notes text,
  assignees uuid[] default '{}'::uuid[],
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now()
);

create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  title text, body text,
  user_id uuid references public.profiles(id) on delete set null,
  user_name text,
  created_at timestamptz default now()
);

create table if not exists public.recommendations (
  id uuid primary key default gen_random_uuid(),
  condition text, part text, reason text, site text, location text,
  user_id uuid references public.profiles(id) on delete set null,
  user_name text,
  created_at timestamptz default now()
);

create table if not exists public.leave_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  user_name text,
  type text check (type in ('sick','emergency','vacation')),
  start_date date, end_date date,
  days int,
  reason text,
  status text default 'pending' check (status in ('pending','approved','rejected')),
  reviewed_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  title text, body text, link text,
  read boolean default false,
  created_at timestamptz default now()
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  kind text check (kind in ('dm','group')),
  name text,
  members uuid[] default '{}'::uuid[],
  created_by uuid references public.profiles(id) on delete set null,
  last_message text, last_at timestamptz default now(),
  archived_by uuid[] default '{}'::uuid[],
  created_at timestamptz default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid references public.conversations(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete set null,
  user_name text,
  body text,
  attachment_url text, attachment_type text,
  reply_to uuid references public.messages(id) on delete set null,
  reactions jsonb default '{}'::jsonb,
  pinned boolean default false,
  edited boolean default false,
  deleted boolean default false,
  created_at timestamptz default now()
);

create table if not exists public.chat_reads (
  conversation_id uuid references public.conversations(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  last_read_at timestamptz default now(),
  primary key (conversation_id, user_id)
);

-- ===== New-user trigger =====
create or replace function public.handle_new_user() returns trigger language plpgsql security definer as $$
declare
  v_count int;
  v_role text := coalesce(new.raw_user_meta_data->>'role','technician');
  v_status text := 'pending';
begin
  select count(*) into v_count from public.profiles;
  if v_count = 0 then
    v_role := 'admin';
    v_status := 'approved';
  end if;
  insert into public.profiles (id, email, name, id_no, address, team, phone, area, role, status)
  values (
    new.id, new.email,
    coalesce(new.raw_user_meta_data->>'name', new.email),
    new.raw_user_meta_data->>'id_no',
    new.raw_user_meta_data->>'address',
    new.raw_user_meta_data->>'team',
    new.raw_user_meta_data->>'phone',
    new.raw_user_meta_data->>'area',
    v_role, v_status
  ) on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

-- ===== RLS =====
do $$ declare t text; begin
  foreach t in array array[
    'profiles','sites','units','reports','pms_records','dtr_entries','dtr_signatures',
    'announcements','schedules','notes','recommendations','leave_requests',
    'notifications','conversations','messages','chat_reads'
  ] loop
    execute format('alter table public.%I enable row level security;', t);
  end loop;
end $$;

-- Profiles
create policy "profiles_read_all" on public.profiles for select to authenticated using (true);
create policy "profiles_insert_self" on public.profiles for insert to authenticated with check (id = auth.uid());
create policy "profiles_update_self" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy "profiles_update_admin" on public.profiles for update to authenticated using (public.is_admin());
create policy "profiles_delete_admin" on public.profiles for delete to authenticated using (public.is_admin());

-- Generic read-all + insert-own + update-own + admin delete for most tables
do $$
declare t text;
begin
  foreach t in array array['sites','units','reports','pms_records','announcements','schedules','notes','recommendations'] loop
    execute format('create policy "%I_read" on public.%I for select to authenticated using (true);', t, t);
    execute format('create policy "%I_insert" on public.%I for insert to authenticated with check (true);', t, t);
    execute format('create policy "%I_update_own_or_manager" on public.%I for update to authenticated using (public.is_manager());', t, t);
    execute format('create policy "%I_delete_own_or_manager" on public.%I for delete to authenticated using (public.is_manager());', t, t);
  end loop;
end $$;

-- DTR
create policy "dtr_read" on public.dtr_entries for select to authenticated using (true);
create policy "dtr_insert_own" on public.dtr_entries for insert to authenticated with check (user_id = auth.uid());
create policy "dtr_update_own_or_manager" on public.dtr_entries for update to authenticated using (user_id = auth.uid() or public.is_manager());
create policy "dtr_delete_own_or_manager" on public.dtr_entries for delete to authenticated using (user_id = auth.uid() or public.is_manager());

create policy "sig_read" on public.dtr_signatures for select to authenticated using (true);
create policy "sig_upsert_own" on public.dtr_signatures for insert to authenticated with check (user_id = auth.uid());
create policy "sig_update_own" on public.dtr_signatures for update to authenticated using (user_id = auth.uid());

-- Leaves
create policy "leave_read_own_or_manager" on public.leave_requests for select to authenticated using (user_id = auth.uid() or public.is_manager());
create policy "leave_insert_own" on public.leave_requests for insert to authenticated with check (user_id = auth.uid());
create policy "leave_update_own_pending_or_manager" on public.leave_requests for update to authenticated using ((user_id = auth.uid() and status = 'pending') or public.is_manager());

-- Notifications
create policy "notif_read" on public.notifications for select to authenticated using (user_id = auth.uid() or user_id is null or public.is_manager());
create policy "notif_update_own" on public.notifications for update to authenticated using (user_id = auth.uid() or user_id is null);
create policy "notif_insert" on public.notifications for insert to authenticated with check (true);

-- Chat
create policy "conv_read_members" on public.conversations for select to authenticated using (auth.uid() = any(members) or public.is_manager());
create policy "conv_insert" on public.conversations for insert to authenticated with check (auth.uid() = created_by);
create policy "conv_update_members" on public.conversations for update to authenticated using (auth.uid() = any(members));

create policy "msg_read" on public.messages for select to authenticated using (true);
create policy "msg_insert_own" on public.messages for insert to authenticated with check (user_id = auth.uid());
create policy "msg_update_own_or_pin" on public.messages for update to authenticated using (user_id = auth.uid() or public.is_manager());
create policy "msg_delete_own_or_admin" on public.messages for delete to authenticated using (user_id = auth.uid() or public.is_admin());

create policy "reads_own" on public.chat_reads for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ===== Storage buckets =====
insert into storage.buckets (id, name, public) values
  ('avatars','avatars',true),
  ('covers','covers',true),
  ('reports','reports',true),
  ('chat','chat',true),
  ('signatures','signatures',true)
on conflict (id) do nothing;

drop policy if exists "storage_read_all" on storage.objects;
create policy "storage_read_all" on storage.objects for select to authenticated using (true);
drop policy if exists "storage_write_auth" on storage.objects;
create policy "storage_write_auth" on storage.objects for insert to authenticated with check (true);
drop policy if exists "storage_update_auth" on storage.objects;
create policy "storage_update_auth" on storage.objects for update to authenticated using (true);
drop policy if exists "storage_delete_auth" on storage.objects;
create policy "storage_delete_auth" on storage.objects for delete to authenticated using (true);

-- ===== Realtime =====
do $$ begin
  alter publication supabase_realtime add table public.messages;
exception when others then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.conversations;
exception when others then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.notifications;
exception when others then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.announcements;
exception when others then null; end $$;