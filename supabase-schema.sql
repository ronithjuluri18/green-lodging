-- ============================================================================
--  GREEN LODGING LLC — Property Management Database
--  Paste this WHOLE file into Supabase → SQL Editor → Run.
--  Safe to run more than once.
-- ============================================================================

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- 1. ROLES
-- ---------------------------------------------------------------------------
do $$ begin
  create type app_role as enum ('owner','manager','tenant');
exception when duplicate_object then null; end $$;

create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text,
  email       text,
  phone       text,
  role        app_role not null default 'tenant',
  is_active   boolean  not null default true,
  created_at  timestamptz not null default now()
);

-- Every new sign-up automatically gets a profile, defaulting to "tenant".
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, phone, full_name)
  values (new.id, new.email, new.phone,
          coalesce(new.raw_user_meta_data->>'full_name', split_part(coalesce(new.email,''),'@',1)))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- 2. WHO AM I?  (security definer = these can read profiles without recursion)
-- ---------------------------------------------------------------------------
-- Turns a text folder name into a uuid, or null if it isn't one (never errors).
create or replace function public.safe_uuid(t text) returns uuid
language plpgsql immutable as $$
begin return t::uuid; exception when others then return null; end $$;

create or replace function public.my_role() returns app_role
language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid() and is_active
$$;

create or replace function public.is_staff() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select role in ('owner','manager') from public.profiles
                   where id = auth.uid() and is_active), false)
$$;

create or replace function public.is_owner() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select role = 'owner' from public.profiles
                   where id = auth.uid() and is_active), false)
$$;

-- ---------------------------------------------------------------------------
-- 3. PROPERTY
-- ---------------------------------------------------------------------------
create table if not exists public.buildings (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  address    text,
  city       text default 'Brooklyn',
  state      text default 'NY',
  zip        text,
  block_lot  text,
  dhcr_id    text,
  notes      text,
  created_at timestamptz not null default now()
);

create table if not exists public.units (
  id            uuid primary key default gen_random_uuid(),
  building_id   uuid not null references public.buildings(id) on delete cascade,
  label         text not null,
  unit_type     text not null default 'apartment',   -- apartment | commercial
  is_stabilized boolean not null default true,
  legal_rent    numeric(12,2),
  notes         text,
  created_at    timestamptz not null default now(),
  unique (building_id, label)
);

-- Which tenant account belongs to which apartment.
create table if not exists public.tenancies (
  id         uuid primary key default gen_random_uuid(),
  unit_id    uuid not null references public.units(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  moved_in   date default current_date,
  moved_out  date,
  unique (unit_id, profile_id)
);

create or replace function public.my_unit_ids() returns setof uuid
language sql stable security definer set search_path = public as $$
  select unit_id from public.tenancies
   where profile_id = auth.uid()
     and (moved_out is null or moved_out >= current_date)
$$;

create or replace function public.my_building_ids() returns setof uuid
language sql stable security definer set search_path = public as $$
  select distinct u.building_id from public.units u
   where u.id in (select public.my_unit_ids())
$$;

-- ---------------------------------------------------------------------------
-- 4. LEASES
-- ---------------------------------------------------------------------------
create table if not exists public.leases (
  id            uuid primary key default gen_random_uuid(),
  unit_id       uuid not null references public.units(id) on delete cascade,
  tenant_name   text not null,
  tenant_phone  text,
  tenant_email  text,
  start_date    date not null,
  end_date      date not null,
  monthly_rent  numeric(12,2) not null default 0,
  rent_due_day  int  not null default 1 check (rent_due_day between 1 and 28),
  rider_signed  boolean not null default false,
  preferential  boolean not null default false,
  notes         text,
  created_at    timestamptz not null default now()
);
create index if not exists leases_unit_idx on public.leases(unit_id);

-- ---------------------------------------------------------------------------
-- 5. RENT LEDGER  (one row per unit per month)
-- ---------------------------------------------------------------------------
create table if not exists public.rent_payments (
  id          uuid primary key default gen_random_uuid(),
  unit_id     uuid not null references public.units(id) on delete cascade,
  lease_id    uuid references public.leases(id) on delete set null,
  period      text not null,                     -- 'YYYY-MM'
  amount_due  numeric(12,2) not null default 0,
  amount_paid numeric(12,2) not null default 0,
  paid_date   date,
  method      text,
  reference   text,
  proof_path  text,
  note        text,
  recorded_by uuid references public.profiles(id),
  created_at  timestamptz not null default now(),
  unique (unit_id, period)
);
create index if not exists rent_unit_period_idx on public.rent_payments(unit_id, period);

-- ---------------------------------------------------------------------------
-- 6. UTILITIES
-- ---------------------------------------------------------------------------
create table if not exists public.utility_accounts (
  id             uuid primary key default gen_random_uuid(),
  building_id    uuid not null references public.buildings(id) on delete cascade,
  utility_type   text not null,                  -- water | gas | electric | oil | other
  provider       text,
  account_number text,
  due_day        int check (due_day between 1 and 28),
  cycle_months   int not null default 1,
  notes          text
);

create table if not exists public.utility_bills (
  id             uuid primary key default gen_random_uuid(),
  building_id    uuid not null references public.buildings(id) on delete cascade,
  unit_id        uuid references public.units(id) on delete set null,
  account_id     uuid references public.utility_accounts(id) on delete set null,
  utility_type   text not null,
  provider       text,
  period_label   text,
  amount         numeric(12,2) not null default 0,
  bill_date      date,
  due_date       date not null,
  paid_date      date,
  method         text,
  bill_path      text,
  proof_path     text,
  note           text,
  created_at     timestamptz not null default now()
);
create index if not exists util_bills_due_idx on public.utility_bills(due_date);

-- ---------------------------------------------------------------------------
-- 7. COMPLAINTS
-- ---------------------------------------------------------------------------
create table if not exists public.complaints (
  id           uuid primary key default gen_random_uuid(),
  building_id  uuid not null references public.buildings(id) on delete cascade,
  unit_id      uuid references public.units(id) on delete set null,
  source       text not null default 'tenant',    -- tenant | hpd | dob | 311 | internal
  category     text,
  title        text not null,
  description  text,
  opened_date  date not null default current_date,
  status       text not null default 'open',      -- open | in_progress | resolved
  case_number  text,
  closed_date  date,
  created_by   uuid references public.profiles(id),
  created_at   timestamptz not null default now()
);
create index if not exists complaints_status_idx on public.complaints(status, opened_date);

create table if not exists public.complaint_updates (
  id           uuid primary key default gen_random_uuid(),
  complaint_id uuid not null references public.complaints(id) on delete cascade,
  update_date  date not null default current_date,
  note         text not null,
  file_path    text,
  author_id    uuid references public.profiles(id),
  author_name  text,
  created_at   timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 8. DOCUMENTS
-- ---------------------------------------------------------------------------
create table if not exists public.documents (
  id             uuid primary key default gen_random_uuid(),
  building_id    uuid references public.buildings(id) on delete cascade,
  unit_id        uuid references public.units(id) on delete set null,
  category       text not null default 'Other',
  name           text not null,
  storage_path   text not null,
  size_bytes     bigint,
  content_type   text,
  tenant_visible boolean not null default false,
  note           text,
  uploaded_by    uuid references public.profiles(id),
  uploaded_at    timestamptz not null default now()
);
create index if not exists documents_unit_idx on public.documents(unit_id);

-- ---------------------------------------------------------------------------
-- 9. INVITE CODES  (how a tenant claims their apartment)
-- ---------------------------------------------------------------------------
create table if not exists public.unit_invites (
  code       text primary key,
  unit_id    uuid not null references public.units(id) on delete cascade,
  label      text,
  expires_at date,
  used_by    uuid references public.profiles(id),
  used_at    timestamptz,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

-- A signed-in user hands in their code; this links them to their apartment.
create or replace function public.redeem_invite(p_code text, p_full_name text, p_phone text)
returns json language plpgsql security definer set search_path = public as $$
declare v public.unit_invites;
begin
  if auth.uid() is null then
    return json_build_object('ok', false, 'error', 'You must be signed in first.');
  end if;

  select * into v from public.unit_invites
   where upper(code) = upper(trim(p_code))
     and used_by is null
     and (expires_at is null or expires_at >= current_date);

  if not found then
    return json_build_object('ok', false,
      'error', 'That code is not valid, or it has already been used. Ask your landlord for a new one.');
  end if;

  update public.profiles
     set full_name = coalesce(nullif(trim(p_full_name),''), full_name),
         phone     = coalesce(nullif(trim(p_phone),''), phone),
         role      = case when role = 'tenant' then 'tenant' else role end
   where id = auth.uid();

  insert into public.tenancies (unit_id, profile_id)
  values (v.unit_id, auth.uid())
  on conflict (unit_id, profile_id) do nothing;

  update public.unit_invites
     set used_by = auth.uid(), used_at = now()
   where code = v.code;

  return json_build_object('ok', true);
end $$;

grant execute on function public.redeem_invite(text,text,text) to authenticated;

-- ---------------------------------------------------------------------------
-- 10. ROW LEVEL SECURITY  — the part that keeps tenants in their own apartment
-- ---------------------------------------------------------------------------
alter table public.profiles         enable row level security;
alter table public.buildings        enable row level security;
alter table public.units            enable row level security;
alter table public.tenancies        enable row level security;
alter table public.leases           enable row level security;
alter table public.rent_payments    enable row level security;
alter table public.utility_accounts enable row level security;
alter table public.utility_bills    enable row level security;
alter table public.complaints       enable row level security;
alter table public.complaint_updates enable row level security;
alter table public.documents        enable row level security;
alter table public.unit_invites     enable row level security;

-- Drop-and-recreate so the file is re-runnable
do $$
declare r record;
begin
  for r in select schemaname, tablename, policyname from pg_policies where schemaname='public'
  loop execute format('drop policy if exists %I on %I.%I', r.policyname, r.schemaname, r.tablename);
  end loop;
end $$;

-- PROFILES ------------------------------------------------------------------
create policy p_profiles_read on public.profiles for select
  using ( id = auth.uid() or public.is_staff() );
create policy p_profiles_self_update on public.profiles for update
  using ( id = auth.uid() ) with check ( id = auth.uid() and role = public.my_role() );
create policy p_profiles_owner_all on public.profiles for all
  using ( public.is_owner() ) with check ( public.is_owner() );

-- BUILDINGS -----------------------------------------------------------------
create policy p_buildings_read on public.buildings for select
  using ( public.is_staff() or id in (select public.my_building_ids()) );
create policy p_buildings_write on public.buildings for insert with check ( public.is_staff() );
create policy p_buildings_update on public.buildings for update using ( public.is_staff() ) with check ( public.is_staff() );
create policy p_buildings_delete on public.buildings for delete using ( public.is_owner() );

-- UNITS ---------------------------------------------------------------------
create policy p_units_read on public.units for select
  using ( public.is_staff() or id in (select public.my_unit_ids()) );
create policy p_units_write on public.units for insert with check ( public.is_staff() );
create policy p_units_update on public.units for update using ( public.is_staff() ) with check ( public.is_staff() );
create policy p_units_delete on public.units for delete using ( public.is_owner() );

-- TENANCIES -----------------------------------------------------------------
create policy p_tenancies_read on public.tenancies for select
  using ( public.is_staff() or profile_id = auth.uid() );
create policy p_tenancies_write on public.tenancies for insert with check ( public.is_staff() );
create policy p_tenancies_update on public.tenancies for update using ( public.is_staff() ) with check ( public.is_staff() );
create policy p_tenancies_delete on public.tenancies for delete using ( public.is_owner() );

-- LEASES --------------------------------------------------------------------
create policy p_leases_read on public.leases for select
  using ( public.is_staff() or unit_id in (select public.my_unit_ids()) );
create policy p_leases_write on public.leases for insert with check ( public.is_staff() );
create policy p_leases_update on public.leases for update using ( public.is_staff() ) with check ( public.is_staff() );
create policy p_leases_delete on public.leases for delete using ( public.is_owner() );

-- RENT ----------------------------------------------------------------------
create policy p_rent_read on public.rent_payments for select
  using ( public.is_staff() or unit_id in (select public.my_unit_ids()) );
create policy p_rent_write on public.rent_payments for insert with check ( public.is_staff() );
create policy p_rent_update on public.rent_payments for update using ( public.is_staff() ) with check ( public.is_staff() );
create policy p_rent_delete on public.rent_payments for delete using ( public.is_owner() );

-- UTILITY ACCOUNTS — staff only --------------------------------------------
create policy p_uacct_read on public.utility_accounts for select using ( public.is_staff() );
create policy p_uacct_write on public.utility_accounts for insert with check ( public.is_staff() );
create policy p_uacct_update on public.utility_accounts for update using ( public.is_staff() ) with check ( public.is_staff() );
create policy p_uacct_delete on public.utility_accounts for delete using ( public.is_owner() );

-- UTILITY BILLS — tenants see only bills tied to their own unit -------------
create policy p_ubill_read on public.utility_bills for select
  using ( public.is_staff() or (unit_id is not null and unit_id in (select public.my_unit_ids())) );
create policy p_ubill_write on public.utility_bills for insert with check ( public.is_staff() );
create policy p_ubill_update on public.utility_bills for update using ( public.is_staff() ) with check ( public.is_staff() );
create policy p_ubill_delete on public.utility_bills for delete using ( public.is_owner() );

-- COMPLAINTS — tenants read + file their own --------------------------------
create policy p_compl_read on public.complaints for select
  using ( public.is_staff()
          or created_by = auth.uid()
          or (unit_id is not null and unit_id in (select public.my_unit_ids())) );
create policy p_compl_insert on public.complaints for insert
  with check ( public.is_staff()
               or (unit_id is not null and unit_id in (select public.my_unit_ids())
                   and created_by = auth.uid() and source = 'tenant') );
create policy p_compl_update on public.complaints for update
  using ( public.is_staff() ) with check ( public.is_staff() );
create policy p_compl_delete on public.complaints for delete using ( public.is_owner() );

-- COMPLAINT UPDATES ---------------------------------------------------------
create policy p_cupd_read on public.complaint_updates for select
  using ( public.is_staff()
          or complaint_id in (select id from public.complaints
                               where created_by = auth.uid()
                                  or (unit_id is not null and unit_id in (select public.my_unit_ids()))) );
create policy p_cupd_insert on public.complaint_updates for insert
  with check ( public.is_staff()
               or complaint_id in (select id from public.complaints
                                    where unit_id is not null
                                      and unit_id in (select public.my_unit_ids())) );
create policy p_cupd_update on public.complaint_updates for update using ( public.is_staff() ) with check ( public.is_staff() );
create policy p_cupd_delete on public.complaint_updates for delete using ( public.is_owner() );

-- DOCUMENTS — tenants see only what is marked visible to them ---------------
create policy p_docs_read on public.documents for select
  using ( public.is_staff()
          or (tenant_visible and unit_id is not null and unit_id in (select public.my_unit_ids())) );
create policy p_docs_insert on public.documents for insert
  with check ( public.is_staff()
               or (unit_id is not null and unit_id in (select public.my_unit_ids())
                   and uploaded_by = auth.uid()) );
create policy p_docs_update on public.documents for update using ( public.is_staff() ) with check ( public.is_staff() );
create policy p_docs_delete on public.documents for delete using ( public.is_owner() );

-- INVITES — staff only ------------------------------------------------------
create policy p_inv_read on public.unit_invites for select using ( public.is_staff() );
create policy p_inv_write on public.unit_invites for insert with check ( public.is_staff() );
create policy p_inv_update on public.unit_invites for update using ( public.is_staff() ) with check ( public.is_staff() );
create policy p_inv_delete on public.unit_invites for delete using ( public.is_owner() );

-- ---------------------------------------------------------------------------
-- 11. FILE STORAGE
--     Paths:  s/<building_id>/...   staff only
--             t/<unit_id>/...       that unit's tenant may read
--             t/<unit_id>/inbox/... that unit's tenant may also upload
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('docs','docs', false)
on conflict (id) do nothing;

-- Supabase enables this already; we assert it so the rules below can never be
-- silently bypassed. If it errors because the table is owned by the storage
-- admin, that means it is already on, which is exactly what we want.
do $$ begin
  execute 'alter table storage.objects enable row level security';
exception when others then null; end $$;

do $$
declare r record;
begin
  for r in select policyname from pg_policies
            where schemaname='storage' and tablename='objects' and policyname like 'gl_%'
  loop execute format('drop policy if exists %I on storage.objects', r.policyname); end loop;
end $$;

create policy gl_staff_all on storage.objects for all
  using ( bucket_id = 'docs' and public.is_staff() )
  with check ( bucket_id = 'docs' and public.is_staff() );

create policy gl_tenant_read on storage.objects for select
  using (
    bucket_id = 'docs'
    and (storage.foldername(name))[1] = 't'
    and public.safe_uuid((storage.foldername(name))[2]) in (select public.my_unit_ids())
  );

create policy gl_tenant_upload on storage.objects for insert
  with check (
    bucket_id = 'docs'
    and (storage.foldername(name))[1] = 't'
    and public.safe_uuid((storage.foldername(name))[2]) in (select public.my_unit_ids())
    and (storage.foldername(name))[3] = 'inbox'
  );

-- ---------------------------------------------------------------------------
-- 12. YOUR FIVE BUILDINGS
-- ---------------------------------------------------------------------------
create unique index if not exists buildings_name_key on public.buildings (name);

insert into public.buildings (name, address, zip) values
  ('1403 Fulton Street',    '1403 Fulton Street, Brooklyn, NY',     '11216'),
  ('2165 Pacific Street',   '2165 Pacific Street, Brooklyn, NY',    '11226'),
  ('42 Ralph Avenue',       '42 Ralph Avenue, Brooklyn, NY',        '11221'),
  ('266-268 Throop Avenue', '266-268 Throop Avenue, Brooklyn, NY',  '11206'),
  ('612 Marlborough Road',  '612 Marlborough Rd, Brooklyn, NY',     '11226')
on conflict (name) do nothing;

-- ---------------------------------------------------------------------------
-- DONE. Next: sign up on your own website, then come back here and run:
--   update public.profiles set role = 'owner' where email = 'YOUR-EMAIL-HERE';
-- ---------------------------------------------------------------------------
