-- ============================================================================
--  GREEN LODGING LLC — UPGRADE 2
--  Splits rent into a government share and a tenant share.
--
--  Run this ONCE in Supabase → SQL Editor → New query → Run.
--  It only ADDS things. Nothing you have already entered is changed or lost.
--  Safe to run more than once.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. THE SUBSIDY ON THE LEASE
--    Who pays what, agreed once per lease rather than retyped every month.
-- ---------------------------------------------------------------------------
alter table public.leases add column if not exists subsidy_program  text;
alter table public.leases add column if not exists subsidy_amount   numeric(12,2) not null default 0;
alter table public.leases add column if not exists subsidy_case_no  text;
alter table public.leases add column if not exists subsidy_start    date;

comment on column public.leases.subsidy_program is
  'Section 8 (HCV) | CityFHEPS | FHEPS | HASA | SCRIE | DRIE | Other | null = none';
comment on column public.leases.subsidy_amount is
  'The agency share of the monthly rent. Tenant share = monthly_rent - subsidy_amount.';

-- SCRIE and DRIE freeze the rent and pay you through a property tax credit.
-- No money arrives, so they must never be recorded as an expected payment.
create or replace function public.pays_cash(p text) returns boolean
language sql immutable as $$
  select coalesce(p, '') not in ('', 'SCRIE', 'DRIE', 'None')
$$;

-- ---------------------------------------------------------------------------
-- 2. THE TWO PAYMENTS EACH MONTH
-- ---------------------------------------------------------------------------
alter table public.rent_payments add column if not exists tenant_paid     numeric(12,2) not null default 0;
alter table public.rent_payments add column if not exists govt_paid       numeric(12,2) not null default 0;
alter table public.rent_payments add column if not exists govt_program    text;
alter table public.rent_payments add column if not exists govt_paid_date  date;
alter table public.rent_payments add column if not exists govt_ref        text;
alter table public.rent_payments add column if not exists govt_proof_path text;
alter table public.rent_payments add column if not exists tenant_due      numeric(12,2);
alter table public.rent_payments add column if not exists govt_due        numeric(12,2);

-- Everything recorded before today was money from the tenant.
update public.rent_payments
   set tenant_paid = amount_paid
 where tenant_paid = 0 and amount_paid > 0;

comment on column public.rent_payments.amount_paid is
  'Total received = tenant_paid + govt_paid. Kept in step by the website.';

-- ---------------------------------------------------------------------------
-- 3. ONE PLACE TO READ THE WHOLE PICTURE
--    Used by the rent table, the arrears alerts and the tenant portal.
-- ---------------------------------------------------------------------------
create or replace view public.rent_ledger as
select
  r.id, r.unit_id, r.lease_id, r.period,
  u.building_id,
  l.tenant_name,
  l.subsidy_program,
  l.rent_due_day,
  r.amount_due,
  coalesce(r.govt_due,   l.subsidy_amount)                     as govt_due,
  coalesce(r.tenant_due, r.amount_due - l.subsidy_amount)      as tenant_due,
  r.govt_paid,
  r.tenant_paid,
  (r.govt_paid + r.tenant_paid)                                as total_paid,
  coalesce(r.tenant_due, r.amount_due - l.subsidy_amount) - r.tenant_paid as tenant_balance,
  coalesce(r.govt_due,   l.subsidy_amount)                     - r.govt_paid   as govt_balance,
  r.paid_date, r.govt_paid_date, r.method, r.reference, r.govt_ref,
  r.proof_path, r.govt_proof_path, r.note
from public.rent_payments r
join public.units  u on u.id = r.unit_id
left join public.leases l on l.id = r.lease_id;

alter view public.rent_ledger set (security_invoker = on);
grant select on public.rent_ledger to authenticated;

-- ---------------------------------------------------------------------------
-- 4. HPD / DOB NOTICES — a tenant may now see the ones on their own apartment
-- ---------------------------------------------------------------------------
drop policy if exists p_compl_read on public.complaints;
create policy p_compl_read on public.complaints for select
  using ( public.is_staff()
          or created_by = auth.uid()
          or (unit_id is not null and unit_id in (select public.my_unit_ids())) );

-- ---------------------------------------------------------------------------
-- 5. COMPLAINTS MADE *ABOUT* A TENANT
--    The tenant sees the complaint, never who reported it.
-- ---------------------------------------------------------------------------
alter table public.complaints add column if not exists about_unit_id uuid references public.units(id) on delete set null;
alter table public.complaints add column if not exists reporter_hidden boolean not null default true;

comment on column public.complaints.about_unit_id is
  'Set when the complaint is AGAINST this unit (noise, damage, smoke) rather than from it.';

drop policy if exists p_compl_read_about on public.complaints;
create policy p_compl_read_about on public.complaints for select
  using ( about_unit_id is not null and about_unit_id in (select public.my_unit_ids()) );

-- ---------------------------------------------------------------------------
-- 6. RENT INCREASE HISTORY — already in your leases, now easy to read
-- ---------------------------------------------------------------------------
create or replace view public.rent_history as
select
  l.unit_id,
  u.building_id,
  l.id as lease_id,
  l.start_date,
  l.end_date,
  l.tenant_name,
  l.monthly_rent,
  l.subsidy_amount,
  l.monthly_rent - l.subsidy_amount as tenant_share,
  lag(l.monthly_rent) over (partition by l.unit_id order by l.start_date) as previous_rent,
  l.monthly_rent - lag(l.monthly_rent) over (partition by l.unit_id order by l.start_date) as increase,
  round(
    case when lag(l.monthly_rent) over (partition by l.unit_id order by l.start_date) > 0
      then (l.monthly_rent - lag(l.monthly_rent) over (partition by l.unit_id order by l.start_date))
           / lag(l.monthly_rent) over (partition by l.unit_id order by l.start_date) * 100
    end, 2) as increase_pct
from public.leases l
join public.units u on u.id = l.unit_id;

alter view public.rent_history set (security_invoker = on);
grant select on public.rent_history to authenticated;

-- ---------------------------------------------------------------------------
-- 7. TURNING A TENANT LOGIN OFF AT MOVE-OUT
-- ---------------------------------------------------------------------------
alter table public.profiles add column if not exists last_seen_at timestamptz;
alter table public.profiles add column if not exists disabled_at  timestamptz;

drop policy if exists p_profiles_mgr_update on public.profiles;
create policy p_profiles_mgr_update on public.profiles for update
  using ( public.is_staff() and role = 'tenant' )
  with check ( public.is_staff() and role = 'tenant' );

-- ---------------------------------------------------------------------------
-- DONE. Nothing else to do — reload your website and the new columns appear.
-- ---------------------------------------------------------------------------
