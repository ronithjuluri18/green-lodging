-- ============================================================================
--  GREEN LODGING LLC — UPGRADE 5
--  Two new things you can record against each apartment:
--
--    * what the TENANT hands over each month
--    * a free-text note for concerns, disputes and part payments
--      (for example: "Paying only $900 instead of $1,200" or "Due $30")
--
--  What the AGENCY pays already had a home, so nothing new is needed for it.
--
--  Run ONCE in Supabase -> SQL Editor. Only adds. Safe to run twice.
-- ============================================================================

alter table public.units add column if not exists tenant_pays numeric(12,2);
alter table public.units add column if not exists concerns    text;

comment on column public.units.tenant_pays is
  'What the tenant pays out of their own pocket each month. Leave blank and the site works it out as rent minus the agency share.';
comment on column public.units.concerns is
  'Free text: part payments, disputes, anything worth remembering about this tenancy.';

-- Keep the "what is charged right now" summary in step with the new columns.
-- It is rebuilt from scratch because one of its columns changes name, and
-- Postgres will not rename a column inside an existing view. Nothing is lost:
-- this is a saved question, not stored data.
drop view if exists public.unit_current;

create view public.unit_current as
select
  u.id            as unit_id,
  u.building_id,
  u.label,
  u.unit_type,
  coalesce(l.tenant_name, u.current_tenant_name)          as tenant_name,
  coalesce(l.monthly_rent, u.current_rent, 0)             as monthly_rent,
  coalesce(l.rent_due_day, u.rent_due_day, 1)             as rent_due_day,
  coalesce(l.subsidy_program, u.subsidy_program)          as subsidy_program,
  coalesce(l.subsidy_amount, u.subsidy_amount, 0)         as agency_pays,
  coalesce(u.tenant_pays,
           greatest(coalesce(l.monthly_rent, u.current_rent, 0)
                  - coalesce(l.subsidy_amount, u.subsidy_amount, 0), 0))
                                                          as tenant_pays,
  u.concerns,
  l.id                                                    as lease_id,
  l.start_date, l.end_date,
  (l.id is null)                                          as lease_missing,
  (coalesce(l.tenant_name, u.current_tenant_name) is null) as is_vacant
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
select label,
       coalesce(current_tenant_name, 'Vacant') as tenant,
       current_rent, subsidy_amount as agency_pays, tenant_pays, concerns
  from public.units
 order by building_id, label
 limit 10;
