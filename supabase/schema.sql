-- ============================================================
-- OnMyPlate — Supabase Database Schema
-- Run this in the Supabase SQL editor
-- ============================================================

-- ─── Tables ───────────────────────────────────────────────────────────────

create table if not exists plates (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references auth.users(id) on delete cascade,
  name       text not null default 'My Plate',
  design_id  text not null default 'classic',
  share_id   text unique not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists activities (
  id         uuid primary key default gen_random_uuid(),
  plate_id   uuid not null references plates(id) on delete cascade,
  name       text not null,
  percentage double precision not null check (percentage >= 0 and percentage <= 100),
  color      text not null default '#4CAF50',
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists fallen_items (
  id         uuid primary key default gen_random_uuid(),
  plate_id   uuid not null references plates(id) on delete cascade,
  name       text not null,
  emoji      text not null default '😅',
  offset_x   double precision not null default 0,
  offset_y   double precision not null default 0,
  created_at timestamptz not null default now()
);

-- ─── Indexes ──────────────────────────────────────────────────────────────

create index if not exists plates_user_id_idx    on plates(user_id);
create index if not exists plates_share_id_idx   on plates(share_id);
create index if not exists activities_plate_id   on activities(plate_id, sort_order);
create index if not exists fallen_items_plate_id on fallen_items(plate_id, created_at);

-- ─── Auto-update updated_at ───────────────────────────────────────────────

create or replace function update_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists plates_updated_at on plates;
create trigger plates_updated_at
  before update on plates
  for each row execute function update_updated_at();

-- ─── Row-Level Security ───────────────────────────────────────────────────

alter table plates       enable row level security;
alter table activities   enable row level security;
alter table fallen_items enable row level security;

-- Plates: anyone can read (for share links); only owner can write
create policy "plates_read_all"
  on plates for select using (true);

create policy "plates_insert_own"
  on plates for insert with check (auth.uid() = user_id);

create policy "plates_update_own"
  on plates for update using (auth.uid() = user_id);

create policy "plates_delete_own"
  on plates for delete using (auth.uid() = user_id);

-- Activities: readable by all; writable only via own plate
create policy "activities_read_all"
  on activities for select using (true);

create policy "activities_insert_own"
  on activities for insert with check (
    plate_id in (select id from plates where user_id = auth.uid())
  );

create policy "activities_update_own"
  on activities for update using (
    plate_id in (select id from plates where user_id = auth.uid())
  );

create policy "activities_delete_own"
  on activities for delete using (
    plate_id in (select id from plates where user_id = auth.uid())
  );

-- Fallen items: same pattern
create policy "fallen_items_read_all"
  on fallen_items for select using (true);

create policy "fallen_items_insert_own"
  on fallen_items for insert with check (
    plate_id in (select id from plates where user_id = auth.uid())
  );

create policy "fallen_items_update_own"
  on fallen_items for update using (
    plate_id in (select id from plates where user_id = auth.uid())
  );

create policy "fallen_items_delete_own"
  on fallen_items for delete using (
    plate_id in (select id from plates where user_id = auth.uid())
  );

-- ─── Enable anonymous sign-in ─────────────────────────────────────────────
-- In Supabase dashboard → Authentication → Providers → Enable "Anonymous"
-- This lets users get a session without signing up.
