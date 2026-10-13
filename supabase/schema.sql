-- ====================================================================
-- PULSE MUSIC - SUPABASE DATABASE SCHEMA & ROW LEVEL SECURITY (RLS)
-- Run this script in your Supabase Project -> SQL Editor
-- ====================================================================

-- 1. Create Profiles Table (Linked to Supabase Auth)
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text not null,
  display_name text not null default 'Explorer',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. Create Favorites Table (Linked to User & Storing Song Object)
create table if not exists public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null,
  track_id text not null,
  track_data jsonb not null,
  created_at timestamptz not null default now(),
  unique (user_id, track_id)
);

-- 3. Create Playlists Table (Custom User Playlists)
create table if not exists public.playlists (
  id text primary key,
  user_id uuid references auth.users on delete cascade not null,
  name text not null,
  description text default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 4. Create Playlist Tracks Table (Tracks saved in playlists)
create table if not exists public.playlist_tracks (
  id uuid primary key default gen_random_uuid(),
  playlist_id text references public.playlists(id) on delete cascade not null,
  user_id uuid references auth.users on delete cascade not null,
  track_id text not null,
  track_data jsonb not null,
  added_at timestamptz not null default now(),
  unique (playlist_id, track_id)
);

-- ====================================================================
-- ENABLE ROW LEVEL SECURITY (RLS)
-- ====================================================================
alter table public.profiles enable row level security;
alter table public.favorites enable row level security;
alter table public.playlists enable row level security;
alter table public.playlist_tracks enable row level security;

-- ====================================================================
-- ROW LEVEL SECURITY POLICIES (Users access only their own data)
-- ====================================================================

-- Profiles Policies
create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Favorites Policies
create policy "Users can view own favorites"
  on public.favorites for select
  using (auth.uid() = user_id);

create policy "Users can insert own favorites"
  on public.favorites for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own favorites"
  on public.favorites for delete
  using (auth.uid() = user_id);

-- Playlists Policies
create policy "Users can view own playlists"
  on public.playlists for select
  using (auth.uid() = user_id);

create policy "Users can insert own playlists"
  on public.playlists for insert
  with check (auth.uid() = user_id);

create policy "Users can update own playlists"
  on public.playlists for update
  using (auth.uid() = user_id);

create policy "Users can delete own playlists"
  on public.playlists for delete
  using (auth.uid() = user_id);

-- Playlist Tracks Policies
create policy "Users can view own playlist tracks"
  on public.playlist_tracks for select
  using (auth.uid() = user_id);

create policy "Users can insert own playlist tracks"
  on public.playlist_tracks for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own playlist tracks"
  on public.playlist_tracks for delete
  using (auth.uid() = user_id);

-- ====================================================================
-- TRIGGER: Automatically populate profiles table on user signup
-- ====================================================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do update
  set email = excluded.email,
      display_name = coalesce(excluded.display_name, profiles.display_name);
  return new;
end;
$$ language plpgsql security definer;

-- Drop trigger if exists and recreate
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
