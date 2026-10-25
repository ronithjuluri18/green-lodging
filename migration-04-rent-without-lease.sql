-- ============================================================================
--  GREEN LODGING LLC — UPGRADE 4
--  Lets an apartment hold its current rent and tenant name WITHOUT a lease.
--
--  Why: you have the rent and the tenant for most units, but the lease
--  documents are still to come. Until now the site could only hold a rent
--  inside a lease, which would have meant inventing start and end dates.
--  This way nothing is made up, and the leases drop in later without redoing
--  anything.
--
--  Run ONCE in Supabase → SQL Editor. Only adds. Safe to run twice.
-- ============================================================================

alter table public.units add column if not exists current_rent        numeric(12,2);
alter table public.units add column if not exists current_tenant_name text;
alter table public.units add column if not exists rent_due_day        int default 1;
alter table public.units add column if not exists tenant_phone        text;
alter table public.units add column if not exists tenant_email        text;
alter table public.units add column if not exists subsidy_program     text;
alter table public.units add column if not exists subsidy_amount      numeric(12,2) not null default 0;

comment on column public.units.current_rent is
  'What is actually charged today. Used when no lease covers the month. A lease always wins over this.';
comment on column public.units.current_tenant_name is
  'Who lives there now, before the lease paperwork is entered.';
comment on column public.units.rent_due_day is
  'Day of the month the rent falls due. Some tenancies run 15th to 14th.';

do $$ begin
  alter table public.units add constraint units_due_day_ck
    check (rent_due_day is null or (rent_due_day between 1 and 28));
exception when duplicate_object then null; end $$;

-- A rent row no longer has to belong to a lease.
alter table public.rent_payments alter column lease_id drop not null;

-- What is charged for each unit right now, whichever way it was recorded.
create or replace view public.unit_current as
select
  u.id            as unit_id,
  u.building_id,
  u.label,
  u.unit_type,
  coalesce(l.tenant_name, u.current_tenant_name)          as tenant_name,
  coalesce(l.monthly_rent, u.current_rent, 0)             as monthly_rent,
  coalesce(l.rent_due_day, u.rent_due_day, 1)             as rent_due_day,
  coalesce(l.subsidy_program, u.subsidy_program)          as subsidy_program,
  coalesce(l.subsidy_amount, u.subsidy_amount, 0)         as subsidy_amount,
  l.id                                                    as lease_id,
  l.start_date, l.end_date,
  (l.id is null)                                          as lease_missing
from public.units u
left join lateral (
  select * from public.leases l2
   where l2.unit_id = u.id
     and l2.start_date <= current_date
     and l2.end_date   >= current_date
   order by l2.start_date desc
   limit 1
) l on true;

alter view public.unit_current set (security_invoker = on);
grant select on public.unit_current to authenticated;

-- ============================================================================
--  DONE.
-- ============================================================================
