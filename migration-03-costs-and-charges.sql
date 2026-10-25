-- ============================================================================
--  GREEN LODGING LLC — UPGRADE 3
--  Two things your income & expense sheets contain that the site could not hold:
--    1. Operating costs per building (maintenance, insurance, taxes, mortgage…)
--    2. Charges that are not monthly rent — a tax escalation, a late fee, legal
--       costs. Your vet clinic owes $29,564.01 of exactly this kind.
--
--  Run ONCE in Supabase → SQL Editor. Only adds. Safe to run twice.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. WHAT EACH BUILDING COSTS TO RUN
-- ---------------------------------------------------------------------------
create table if not exists public.building_expenses (
  id              uuid primary key default gen_random_uuid(),
  building_id     uuid not null references public.buildings(id) on delete cascade,
  category        text not null,
  monthly_amount  numeric(12,2) not null default 0,
  annual_amount   numeric(12,2) not null default 0,
  kind            text not null default 'operating',   -- operating | debt | tax
  seasonal        boolean not null default false,
  note            text,
  as_of           date,
  sort_order      int not null default 100,
  created_at      timestamptz not null default now(),
  unique (building_id, category)
);

comment on table public.building_expenses is
  'One row per cost line per building, as it appears on an income & expense sheet.';
comment on column public.building_expenses.seasonal is
  'True where the monthly figure only applies to some months (snow removal).';

-- ---------------------------------------------------------------------------
-- 2. CHARGES THAT ARE NOT MONTHLY RENT
-- ---------------------------------------------------------------------------
create table if not exists public.other_charges (
  id            uuid primary key default gen_random_uuid(),
  building_id   uuid not null references public.buildings(id) on delete cascade,
  unit_id       uuid references public.units(id) on delete set null,
  lease_id      uuid references public.leases(id) on delete set null,
  charge_type   text not null default 'Tax escalation',
  description   text,
  period_label  text,
  amount_due    numeric(12,2) not null default 0,
  amount_paid   numeric(12,2) not null default 0,
  due_date      date,
  paid_date     date,
  note          text,
  created_at    timestamptz not null default now()
);
create index if not exists other_charges_unit_idx on public.other_charges(unit_id);

comment on column public.other_charges.charge_type is
  'Tax escalation | Late fee | Legal costs | Repair recharge | Water submeter | Other';

-- ---------------------------------------------------------------------------
-- 3. WHO MAY SEE THEM
--    Operating costs are the owner's business — never a tenant's.
--    A charge against a tenant IS the tenant's business: they must be able to
--    see what they are being billed for.
-- ---------------------------------------------------------------------------
alter table public.building_expenses enable row level security;
alter table public.other_charges     enable row level security;

drop policy if exists p_bexp_read   on public.building_expenses;
drop policy if exists p_bexp_write  on public.building_expenses;
drop policy if exists p_bexp_update on public.building_expenses;
drop policy if exists p_bexp_delete on public.building_expenses;
create policy p_bexp_read   on public.building_expenses for select using ( public.is_staff() );
create policy p_bexp_write  on public.building_expenses for insert with check ( public.is_staff() );
create policy p_bexp_update on public.building_expenses for update using ( public.is_staff() ) with check ( public.is_staff() );
create policy p_bexp_delete on public.building_expenses for delete using ( public.is_owner() );

drop policy if exists p_ochg_read   on public.other_charges;
drop policy if exists p_ochg_write  on public.other_charges;
drop policy if exists p_ochg_update on public.other_charges;
drop policy if exists p_ochg_delete on public.other_charges;
create policy p_ochg_read on public.other_charges for select
  using ( public.is_staff()
          or (unit_id is not null and unit_id in (select public.my_unit_ids())) );
create policy p_ochg_write  on public.other_charges for insert with check ( public.is_staff() );
create policy p_ochg_update on public.other_charges for update using ( public.is_staff() ) with check ( public.is_staff() );
create policy p_ochg_delete on public.other_charges for delete using ( public.is_owner() );

-- ---------------------------------------------------------------------------
-- 4. WHAT A BUILDING EARNS AGAINST WHAT IT COSTS
-- ---------------------------------------------------------------------------
create or replace view public.building_summary as
select
  b.id as building_id,
  b.name,
  (select count(*) from public.units u where u.building_id = b.id)                          as units,
  (select count(*) from public.units u
     where u.building_id = b.id
       and exists (select 1 from public.leases l
                    where l.unit_id = u.id and l.end_date >= current_date))                 as leased,
  coalesce((select sum(l.monthly_rent) from public.leases l
             join public.units u on u.id = l.unit_id
            where u.building_id = b.id
              and l.start_date <= current_date and l.end_date >= current_date), 0)          as monthly_rent_roll,
  coalesce((select sum(e.monthly_amount) from public.building_expenses e
            where e.building_id = b.id and e.kind = 'operating'), 0)                        as monthly_operating,
  coalesce((select sum(e.monthly_amount) from public.building_expenses e
            where e.building_id = b.id), 0)                                                 as monthly_all_costs
from public.buildings b;

alter view public.building_summary set (security_invoker = on);
grant select on public.building_summary to authenticated;

-- ---------------------------------------------------------------------------
-- DONE.
-- ---------------------------------------------------------------------------
