-- ============================================================================
--  GREEN LODGING LLC — YOUR REAL DATA, PART 1
--  1403 Fulton Street  and  2165 Pacific Street
--
--  Everything here comes from the documents supplied. Nothing is invented.
--    * The only lease loaded is the Deli — the one real lease document.
--    * Every other unit carries its rent and tenant name with NO lease dates,
--      because none were supplied. Add the leases when the paperwork arrives.
--    * Rent history is exactly the arrears letters, to the cent.
--    * Nothing about the vet clinic's tax arrears is loaded.
--
--  Run ONCE in Supabase → SQL Editor, AFTER migrations 02, 03 and 04.
--  Safe to run more than once.
-- ============================================================================
begin;

-- ---------------------------------------------------------------- buildings
-- The income sheet prints ZIP 11316 for Fulton; 1403 Fulton St is 11216.
-- The income sheet prints 11226 for Pacific; the Apt 3F letter says 11233.
insert into public.buildings (name, address, city, state, zip, notes) values
  ('1403 Fulton Street', '1403 Fulton Street, Brooklyn, NY', 'Brooklyn', 'NY', '11216', '1403 Fulton Street Corp, 345 East 25 St, Brooklyn NY 11226. Mortgage loan #200425411.')
on conflict (name) do update set address=excluded.address, zip=excluded.zip, notes=excluded.notes;
insert into public.buildings (name, address, city, state, zip, notes) values
  ('2165 Pacific Street', '2165 Pacific Street, Brooklyn, NY', 'Brooklyn', 'NY', '11233', '2165 Pacific Street LLC, 345 East 25 St, Brooklyn NY 11226. Mortgage loan #200465450.')
on conflict (name) do update set address=excluded.address, zip=excluded.zip, notes=excluded.notes;

-- --------------------------------------------------- refuse to clobber your work
do $guard$
declare c int;
begin
  select count(*) into c from public.units u
    join public.buildings b on b.id = u.building_id
   where b.name in ('1403 Fulton Street','2165 Pacific Street')
     and u.id not in ('ce4c643d-273a-55ee-98f6-106a0a9bed54','d03b5705-77ac-5d94-8086-336c3e759253','99834d6b-fdab-5bda-a07b-22e5b1b5e463','dd6d9c2a-9b13-582f-b4c8-00ccdae7ac13','26a4932b-0dba-56e4-b60d-440fc53da3ec','4b9f3c09-9009-53f5-9041-fde71c37e0c8','36b575a7-c4ca-5ac5-a28e-d2b958337d68','38d273bc-841b-52b4-b04d-00df23463b4c','107c4bdd-a749-5683-889e-aff0ece2f699','e9abdeee-31a1-5ddb-a7ba-e6fee0a6e9b7','f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8','b2ca54a5-97ef-566d-8d2c-d8780f04e54d','eb9b48af-549e-5574-8985-5954783094c8','159d93b3-2c4d-5897-b792-7e1a3175e52f','620f1f34-1021-57d9-a75c-0b14c37f7604','a451a25a-6f41-5a06-b3fd-1f24c6f929b0','cb50d405-c75a-5479-b873-c17542dc1db3','e36aeec1-d6c1-5f3a-8935-97e45b49704c','a87bb235-b069-5909-927e-124509a468d2','19639918-596a-5763-9ef7-40be8a0a659c','0ecfb321-a09c-5bf7-a107-746bfae625b8','e6ac4113-4652-5351-b0ae-25cbbb9e2e5d');
  if c > 0 then
    raise exception 'STOPPED: % unit(s) were already entered by hand for these two buildings. Nothing has been changed. Tell Claude before running this file.', c;
  end if;
end $guard$;

-- ------------------------------------------- units, with rent but no lease dates
-- Rent from the income sheet. Tenant name from the notice of 16 Mar 2026. No lease document supplied.
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('ce4c643d-273a-55ee-98f6-106a0a9bed54', (select id from public.buildings where name = '1403 Fulton Street'), 'Vet Office', 'commercial', false, 'Ground floor office',
   3465.00, 'Bedford Stuyvesant Veterinary Clinic — Ms. Tryna Pruden', 1, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;
-- Store lease of 27 Aug 2026 gives $5,000 from 1 Sep 2026. The income sheet still showed the old $4,600.
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('d03b5705-77ac-5d94-8086-336c3e759253', (select id from public.buildings where name = '1403 Fulton Street'), 'Deli', 'commercial', false, 'Ground floor store',
   5000.00, 'Fulton Fresh & Bite — Saleh Algahim', 1, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;
-- Shown at $0 on the income sheet — treated as vacant.
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('99834d6b-fdab-5bda-a07b-22e5b1b5e463', (select id from public.buildings where name = '1403 Fulton Street'), '2A', 'apartment', true, 'Studio',
   0.00, null, 1, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('dd6d9c2a-9b13-582f-b4c8-00ccdae7ac13', (select id from public.buildings where name = '1403 Fulton Street'), '2B', 'apartment', true, '1 bed',
   2100.00, null, 1, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('26a4932b-0dba-56e4-b60d-440fc53da3ec', (select id from public.buildings where name = '1403 Fulton Street'), '2C', 'apartment', true, '1 bed',
   1890.00, null, 1, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('4b9f3c09-9009-53f5-9041-fde71c37e0c8', (select id from public.buildings where name = '1403 Fulton Street'), '2D', 'apartment', true, '1 bed',
   2467.00, null, 1, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('36b575a7-c4ca-5ac5-a28e-d2b958337d68', (select id from public.buildings where name = '1403 Fulton Street'), '3A', 'apartment', true, '1 bed',
   1837.00, null, 1, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('38d273bc-841b-52b4-b04d-00df23463b4c', (select id from public.buildings where name = '1403 Fulton Street'), '3B', 'apartment', true, 'Studio',
   1377.00, null, 1, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;
-- Rent $2,300 from 15 Jan 2026 per the arrears notice of 11 Apr 2026 (the income sheet still showed $1,785). Rent runs the 15th to the 14th.
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('107c4bdd-a749-5683-889e-aff0ece2f699', (select id from public.buildings where name = '1403 Fulton Street'), '3C', 'apartment', true, '1 bed',
   2300.00, 'Leonard Walker', 15, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('e9abdeee-31a1-5ddb-a7ba-e6fee0a6e9b7', (select id from public.buildings where name = '1403 Fulton Street'), '3D', 'apartment', true, '1 bed',
   1890.00, null, 1, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;
-- Rent $1,950 from Dec 2024 per the arrears notice of 14 Jun 2026 (the income sheet still showed $1,785).
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', (select id from public.buildings where name = '1403 Fulton Street'), '4A', 'apartment', true, '1 bed',
   1950.00, 'Markos Eduardo Pimentel', 1, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('b2ca54a5-97ef-566d-8d2c-d8780f04e54d', (select id from public.buildings where name = '1403 Fulton Street'), '4B', 'apartment', true, 'Studio',
   1575.00, null, 1, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('eb9b48af-549e-5574-8985-5954783094c8', (select id from public.buildings where name = '1403 Fulton Street'), '4C', 'apartment', true, '1 bed',
   1470.00, null, 1, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('159d93b3-2c4d-5897-b792-7e1a3175e52f', (select id from public.buildings where name = '1403 Fulton Street'), '4D', 'apartment', true, '1 bed',
   2520.00, null, 1, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;

insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('620f1f34-1021-57d9-a75c-0b14c37f7604', (select id from public.buildings where name = '2165 Pacific Street'), '1F', 'apartment', true, '3 bed',
   2025.45, null, 1, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('a451a25a-6f41-5a06-b3fd-1f24c6f929b0', (select id from public.buildings where name = '2165 Pacific Street'), '1R', 'apartment', true, '2 bed',
   1918.35, null, 1, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('cb50d405-c75a-5479-b873-c17542dc1db3', (select id from public.buildings where name = '2165 Pacific Street'), '2F', 'apartment', true, '3 bed',
   1207.50, null, 1, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('e36aeec1-d6c1-5f3a-8935-97e45b49704c', (select id from public.buildings where name = '2165 Pacific Street'), '2R', 'apartment', true, '2 bed',
   1339.80, null, 1, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;
-- Rent $2,885 per the letter of 14 Jun 2026 (the income sheet showed $2,940). Agency pays $1,686.61 since May 2025, tenant pays $1,198.39. The letter does not name the programme — please set it.
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('a87bb235-b069-5909-927e-124509a468d2', (select id from public.buildings where name = '2165 Pacific Street'), '3F', 'apartment', true, '3 bed',
   2885.00, 'Shamani Salum', 1, 'Other', 1686.61)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('19639918-596a-5763-9ef7-40be8a0a659c', (select id from public.buildings where name = '2165 Pacific Street'), '3R', 'apartment', true, '2 bed',
   1470.00, null, 1, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('0ecfb321-a09c-5bf7-a107-746bfae625b8', (select id from public.buildings where name = '2165 Pacific Street'), '4F', 'apartment', true, '3 bed',
   1705.20, null, 1, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;
insert into public.units (id, building_id, label, unit_type, is_stabilized, notes,
    current_rent, current_tenant_name, rent_due_day, subsidy_program, subsidy_amount) values
  ('e6ac4113-4652-5351-b0ae-25cbbb9e2e5d', (select id from public.buildings where name = '2165 Pacific Street'), '4R', 'apartment', true, '2 bed',
   3008.25, null, 1, null, 0.00)
on conflict (id) do update set unit_type=excluded.unit_type, notes=excluded.notes,
  current_rent=excluded.current_rent, current_tenant_name=excluded.current_tenant_name,
  rent_due_day=excluded.rent_due_day, subsidy_program=excluded.subsidy_program,
  subsidy_amount=excluded.subsidy_amount;

-- --------------------------------- the only lease supplied: the Deli, 27 Aug 2026
insert into public.leases (id, unit_id, tenant_name, start_date, end_date, monthly_rent,
    rent_due_day, rider_signed, subsidy_amount, notes) values
  ('70243527-9b76-5564-8391-a02effc2a9d3', 'd03b5705-77ac-5d94-8086-336c3e759253', 'Fulton Fresh & Bite — Saleh Algahim',
   '2026-09-01', '2027-08-31', 5000.00, 1, false, 0, 'Store lease dated 27 Aug 2026, six-year term, year 1 of 6. Late charge of 2% of the rent if unpaid after the 5th. Tenant also pays 5% of any tax rise above the 2026 base year, plus light and submetered water. Use: Deli / smoke shop.')
on conflict (id) do update set start_date=excluded.start_date, end_date=excluded.end_date,
  monthly_rent=excluded.monthly_rent, notes=excluded.notes;
insert into public.leases (id, unit_id, tenant_name, start_date, end_date, monthly_rent,
    rent_due_day, rider_signed, subsidy_amount, notes) values
  ('b954313e-c261-5c61-be5c-1e7ce3eafcac', 'd03b5705-77ac-5d94-8086-336c3e759253', 'Fulton Fresh & Bite — Saleh Algahim',
   '2027-09-01', '2028-08-31', 5200.00, 1, false, 0, 'Store lease dated 27 Aug 2026, six-year term, year 2 of 6. Late charge of 2% of the rent if unpaid after the 5th. Tenant also pays 5% of any tax rise above the 2026 base year, plus light and submetered water. Use: Deli / smoke shop.')
on conflict (id) do update set start_date=excluded.start_date, end_date=excluded.end_date,
  monthly_rent=excluded.monthly_rent, notes=excluded.notes;
insert into public.leases (id, unit_id, tenant_name, start_date, end_date, monthly_rent,
    rent_due_day, rider_signed, subsidy_amount, notes) values
  ('bf1b18de-a63c-5b95-bae1-4b3990afe750', 'd03b5705-77ac-5d94-8086-336c3e759253', 'Fulton Fresh & Bite — Saleh Algahim',
   '2028-09-01', '2029-08-31', 5400.00, 1, false, 0, 'Store lease dated 27 Aug 2026, six-year term, year 3 of 6. Late charge of 2% of the rent if unpaid after the 5th. Tenant also pays 5% of any tax rise above the 2026 base year, plus light and submetered water. Use: Deli / smoke shop.')
on conflict (id) do update set start_date=excluded.start_date, end_date=excluded.end_date,
  monthly_rent=excluded.monthly_rent, notes=excluded.notes;
insert into public.leases (id, unit_id, tenant_name, start_date, end_date, monthly_rent,
    rent_due_day, rider_signed, subsidy_amount, notes) values
  ('dcebaa36-8bd5-55b5-8b0b-321d067239ca', 'd03b5705-77ac-5d94-8086-336c3e759253', 'Fulton Fresh & Bite — Saleh Algahim',
   '2029-09-01', '2030-08-31', 5600.00, 1, false, 0, 'Store lease dated 27 Aug 2026, six-year term, year 4 of 6. Late charge of 2% of the rent if unpaid after the 5th. Tenant also pays 5% of any tax rise above the 2026 base year, plus light and submetered water. Use: Deli / smoke shop.')
on conflict (id) do update set start_date=excluded.start_date, end_date=excluded.end_date,
  monthly_rent=excluded.monthly_rent, notes=excluded.notes;
insert into public.leases (id, unit_id, tenant_name, start_date, end_date, monthly_rent,
    rent_due_day, rider_signed, subsidy_amount, notes) values
  ('b1adfb41-8654-5431-a7ba-6c420c5a0a10', 'd03b5705-77ac-5d94-8086-336c3e759253', 'Fulton Fresh & Bite — Saleh Algahim',
   '2030-09-01', '2031-08-31', 5800.00, 1, false, 0, 'Store lease dated 27 Aug 2026, six-year term, year 5 of 6. Late charge of 2% of the rent if unpaid after the 5th. Tenant also pays 5% of any tax rise above the 2026 base year, plus light and submetered water. Use: Deli / smoke shop.')
on conflict (id) do update set start_date=excluded.start_date, end_date=excluded.end_date,
  monthly_rent=excluded.monthly_rent, notes=excluded.notes;
insert into public.leases (id, unit_id, tenant_name, start_date, end_date, monthly_rent,
    rent_due_day, rider_signed, subsidy_amount, notes) values
  ('37f39843-c5c0-5caa-a785-01443703234a', 'd03b5705-77ac-5d94-8086-336c3e759253', 'Fulton Fresh & Bite — Saleh Algahim',
   '2031-09-01', '2032-08-31', 6000.00, 1, false, 0, 'Store lease dated 27 Aug 2026, six-year term, year 6 of 6. Late charge of 2% of the rent if unpaid after the 5th. Tenant also pays 5% of any tax rise above the 2026 base year, plus light and submetered water. Use: Deli / smoke shop.')
on conflict (id) do update set start_date=excluded.start_date, end_date=excluded.end_date,
  monthly_rent=excluded.monthly_rent, notes=excluded.notes;

-- ------------------------------ rent history, straight from the arrears letters
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('0a052d76-126c-56a9-af62-47df7ae68ea8', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2022-01', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2022-01-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Jan 2022 to 14 Feb 2022.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('fd5b78cc-fc89-57a1-b81c-a24ae2ddee94', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2022-02', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2022-02-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Feb 2022 to 14 Mar 2022.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('2423b711-1149-59b6-93d2-0bff189ac17f', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2022-03', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2022-03-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Mar 2022 to 14 Apr 2022.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('020ccaad-959e-55c0-92ff-96bbaee8688b', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2022-04', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2022-04-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Apr 2022 to 14 May 2022.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('82be930b-82ab-5faa-bc92-92e6499be2b2', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2022-05', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2022-05-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 May 2022 to 14 Jun 2022.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('72a6d7f6-4006-561f-8c33-d431a92a9bd3', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2022-06', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2022-06-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Jun 2022 to 14 Jul 2022.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('73044a07-6cd9-55c9-a37e-32c13b5ad2f9', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2022-07', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2022-07-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Jul 2022 to 14 Aug 2022.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('03e908dd-84d8-55d7-97b0-5dd7e2a12414', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2022-08', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2022-08-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Aug 2022 to 14 Sep 2022.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('3f569c1c-56eb-5315-9ba9-10c82d5e41fb', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2022-09', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2022-09-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Sep 2022 to 14 Oct 2022.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('382e1306-2823-5f68-9cc0-cecac6a1b1c7', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2022-10', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2022-10-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Oct 2022 to 14 Nov 2022.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('f37a81c2-7a72-51c1-8e76-56d293e70176', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2022-11', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2022-11-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Nov 2022 to 14 Dec 2022.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('65d027ec-15bc-57f9-9d0b-9887c0affd80', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2022-12', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2022-12-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Dec 2022 to 14 Jan 2023.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('a9e68ef5-a00f-5879-b129-d33b96405cd0', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2023-01', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2023-01-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Jan 2023 to 14 Feb 2023.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('fa161bb2-6c5e-501c-bb64-4057a05fb3ed', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2023-02', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2023-02-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Feb 2023 to 14 Mar 2023.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('77cdf369-d13c-54b2-9d5d-d7d37820da3d', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2023-03', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2023-03-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Mar 2023 to 14 Apr 2023.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('b6e92615-32fe-5d6e-95be-c030e85e35ea', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2023-04', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2023-04-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Apr 2023 to 14 May 2023.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('07d8982c-4ba4-56bd-a673-ebad8be14646', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2023-05', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2023-05-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 May 2023 to 14 Jun 2023.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('bba71d9c-f775-5947-b1e4-1d406b342260', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2023-06', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2023-06-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Jun 2023 to 14 Jul 2023.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('bb55f0ae-e70f-579b-ac01-fd26a10421d5', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2023-07', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2023-07-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Jul 2023 to 14 Aug 2023.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('02827bd5-e36b-58c9-aa0e-0f04014a3c20', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2023-08', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2023-08-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Aug 2023 to 14 Sep 2023.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('af5ce38a-eee3-551f-bc39-ab7dbb53974a', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2023-09', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2023-09-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Sep 2023 to 14 Oct 2023.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('cd2a8449-f3d3-5beb-b3f6-8d1be67c28b5', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2023-10', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2023-10-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Oct 2023 to 14 Nov 2023.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('8d24f34a-ffca-53f7-a8e4-640aaaf15e69', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2023-11', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2023-11-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Nov 2023 to 14 Dec 2023.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('8a5480c3-0aae-5464-8536-6816150d4faa', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2023-12', 1799.00, 0.00, 1799.00,
   1598.00, 0.00, 1598.00,
   '2023-12-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Dec 2023 to 14 Jan 2024.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('a0f9f0d6-495c-5ba0-9f3e-9705ee563a5e', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2024-01', 1950.00, 0.00, 1950.00,
   1598.00, 0.00, 1598.00,
   '2024-01-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Jan 2024 to 14 Feb 2024.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('212bc8de-cbf0-586f-b19f-ac9e4f524fa6', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2024-02', 1950.00, 0.00, 1950.00,
   1598.00, 0.00, 1598.00,
   '2024-02-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Feb 2024 to 14 Mar 2024.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('530a2d95-c531-5e5c-a754-ccd326cf2bb1', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2024-03', 1950.00, 0.00, 1950.00,
   1598.00, 0.00, 1598.00,
   '2024-03-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Mar 2024 to 14 Apr 2024.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('48d4b8f5-2bcc-5d1c-8696-52f3ac150bdf', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2024-04', 1950.00, 0.00, 1950.00,
   1598.00, 0.00, 1598.00,
   '2024-04-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Apr 2024 to 14 May 2024.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('b2baf671-5fb1-5779-841c-25bee4cc0c05', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2024-05', 1950.00, 0.00, 1950.00,
   1598.00, 0.00, 1598.00,
   '2024-05-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 May 2024 to 14 Jun 2024.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('49cc0d38-e3e6-5e6e-82db-262616c946bc', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2024-06', 1950.00, 0.00, 1950.00,
   1598.00, 0.00, 1598.00,
   '2024-06-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Jun 2024 to 14 Jul 2024.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('90f6a008-32ba-56f9-b7f9-211e38501be4', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2024-07', 1950.00, 0.00, 1950.00,
   1598.00, 0.00, 1598.00,
   '2024-07-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Jul 2024 to 14 Aug 2024.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('5d725c10-b6d6-5a9d-83ff-75ae2e7a04a1', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2024-08', 1950.00, 0.00, 1950.00,
   1598.00, 0.00, 1598.00,
   '2024-08-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Aug 2024 to 14 Sep 2024.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('12b8f18a-ef5b-5e00-b34e-aa64a01e1c71', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2024-09', 1950.00, 0.00, 1950.00,
   1598.00, 0.00, 1598.00,
   '2024-09-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Sep 2024 to 14 Oct 2024.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('c0aae9cf-b5d6-5b21-b8e2-c15c8c5172f5', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2024-10', 1950.00, 0.00, 1950.00,
   1598.00, 0.00, 1598.00,
   '2024-10-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Oct 2024 to 14 Nov 2024.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('4f93b141-b527-55be-b0a4-945390f89c59', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2024-11', 1950.00, 0.00, 1950.00,
   1598.00, 0.00, 1598.00,
   '2024-11-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Nov 2024 to 14 Dec 2024.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('06b797a8-0f07-541a-866e-2a0d14416a21', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2024-12', 1950.00, 0.00, 1950.00,
   1598.00, 0.00, 1598.00,
   '2024-12-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Dec 2024 to 14 Jan 2025.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('98c89071-9601-5fbc-9052-ce4fbb6f2aa2', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2025-01', 2200.00, 0.00, 2200.00,
   1598.00, 0.00, 1598.00,
   '2025-01-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Jan 2025 to 14 Feb 2025.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('8e288537-53dd-5de6-88f6-8d5e3d68f996', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2025-02', 2200.00, 0.00, 2200.00,
   1598.00, 0.00, 1598.00,
   '2025-02-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Feb 2025 to 14 Mar 2025.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('4d33bf98-9cb7-5186-b4ee-60f8eccddb62', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2025-03', 2200.00, 0.00, 2200.00,
   1598.00, 0.00, 1598.00,
   '2025-03-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Mar 2025 to 14 Apr 2025.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('faa5ae09-f1b9-5770-bceb-480bfd4df8e4', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2025-04', 2200.00, 0.00, 2200.00,
   1598.00, 0.00, 1598.00,
   '2025-04-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Apr 2025 to 14 May 2025.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('e372a2c2-c5bd-5e1c-9459-f59358bca94e', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2025-05', 2200.00, 0.00, 2200.00,
   1598.00, 0.00, 1598.00,
   '2025-05-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 May 2025 to 14 Jun 2025.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('fdcc83d6-a2de-5d6d-b24f-096a63d3ed6c', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2025-06', 2200.00, 0.00, 2200.00,
   1598.00, 0.00, 1598.00,
   '2025-06-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Jun 2025 to 14 Jul 2025.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('4c548197-38ce-58a9-8119-acbd521bd3e3', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2025-07', 2200.00, 0.00, 2200.00,
   1598.00, 0.00, 1598.00,
   '2025-07-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Jul 2025 to 14 Aug 2025.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('0cbbcdef-52d3-5347-a25e-c4f53563544e', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2025-08', 2200.00, 0.00, 2200.00,
   1598.00, 0.00, 1598.00,
   '2025-08-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Aug 2025 to 14 Sep 2025.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('bdb8f42f-4e13-534c-a9bc-84156fb9c5ae', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2025-09', 2200.00, 0.00, 2200.00,
   1598.00, 0.00, 1598.00,
   '2025-09-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Sep 2025 to 14 Oct 2025.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('2fefafba-bac3-583b-b6b8-9c70fee5cf7b', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2025-10', 2200.00, 0.00, 2200.00,
   1598.00, 0.00, 1598.00,
   '2025-10-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Oct 2025 to 14 Nov 2025.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('0237f830-f2cd-5f00-a946-1cc02fa3a772', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2025-11', 2200.00, 0.00, 2200.00,
   1598.00, 0.00, 1598.00,
   '2025-11-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Nov 2025 to 14 Dec 2025.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('6f6a1d1e-cdad-59ac-a2d5-cabdd01fff2f', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2025-12', 2200.00, 0.00, 2200.00,
   1598.00, 0.00, 1598.00,
   '2025-12-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Dec 2025 to 14 Jan 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('1ea0708e-01c1-5ce1-bfbe-e2ec78d950d6', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2026-01', 2300.00, 0.00, 2300.00,
   1598.00, 0.00, 1598.00,
   '2026-01-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Jan 2026 to 14 Feb 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('f1212994-c95b-59b6-b5ae-75eba5c17e8b', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2026-02', 2300.00, 0.00, 2300.00,
   1598.00, 0.00, 1598.00,
   '2026-02-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Feb 2026 to 14 Mar 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('be49e302-7bee-56a2-b6ee-8023942726a8', '107c4bdd-a749-5683-889e-aff0ece2f699', null, '2026-03', 2300.00, 0.00, 2300.00,
   1598.00, 0.00, 1598.00,
   '2026-03-01', 'Check',
   null, null, 'Arrears notice of 11 Apr 2026. Cycle 15 Mar 2026 to 14 Apr 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('5826d646-f806-5e18-8531-c51a20c7d48a', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2022-12', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2022-12-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('4d42728b-ed35-56c1-b2d8-78c6331719a1', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2023-01', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2023-01-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('369d5eb2-95e5-53b0-9a8a-b673fe3db920', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2023-02', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2023-02-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('3e17759a-8c0d-5cba-8018-14eeb2edae86', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2023-03', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2023-03-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('f46feaa9-8a2b-5e1d-9d89-5b473858cf4b', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2023-04', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2023-04-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('f9c49ff4-26f7-5ea0-9e2d-4acfc5e9ab9d', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2023-05', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2023-05-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('b9907fbd-915d-5ca4-bf0e-4ae1e39451ce', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2023-06', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2023-06-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('31ddbdb3-7126-5066-be53-648acd06f227', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2023-07', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2023-07-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('acaa852e-dc79-5ebb-9358-de4339f3f527', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2023-08', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2023-08-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('8e56d435-4a6a-596d-af51-9e8412253abb', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2023-09', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2023-09-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('9a7a4b71-5fc3-51d5-ac26-7868339b8742', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2023-10', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2023-10-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('4a53ae93-cd5b-59d7-a480-06fca190b61a', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2023-11', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2023-11-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('336e5562-fdcc-5caf-b654-d0e4de667d89', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2023-12', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2023-12-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('5dcb8178-676f-52ad-a778-5e033b767def', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2024-01', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2024-01-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('9b04cce0-4676-583a-a833-5402eb2141b3', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2024-02', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2024-02-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('21594065-62dd-5668-a049-ab322fe6528e', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2024-03', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2024-03-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('79f87b3f-b177-53fe-9591-2d80bbf32eca', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2024-04', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2024-04-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('055e9d2b-6182-542e-b61c-7366e234d238', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2024-05', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2024-05-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('7b0e6848-1d8b-5ea3-b5f5-afcf49643b36', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2024-06', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2024-06-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('cc0d1aec-5e46-58ce-86f4-cc68bbf9d00c', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2024-07', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2024-07-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('baf06db2-2237-5e2e-a20a-a6e334038dc3', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2024-08', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2024-08-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('fbbba74b-a887-58b8-8c53-e46d3d896490', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2024-09', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2024-09-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('42b94565-d139-5faa-b97a-784189e6b1f8', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2024-10', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2024-10-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('eccc0d52-e203-52cd-8d8f-702972bef898', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2024-11', 1880.00, 0.00, 1880.00,
   1760.00, 0.00, 1760.00,
   '2024-11-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('6126a29b-eae6-53ac-9055-0fcb7e07916d', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2024-12', 1950.00, 0.00, 1950.00,
   1760.00, 0.00, 1760.00,
   '2024-12-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('c3cb578a-7394-5716-bcb8-25411a7182a7', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2025-01', 1950.00, 0.00, 1950.00,
   1760.00, 0.00, 1760.00,
   '2025-01-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('a3f4022a-ad0b-5f32-ba2e-9c53123a2a66', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2025-02', 1950.00, 0.00, 1950.00,
   1760.00, 0.00, 1760.00,
   '2025-02-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('f4ebdba6-2250-56f2-9d73-837202327f9d', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2025-03', 1950.00, 0.00, 1950.00,
   1760.00, 0.00, 1760.00,
   '2025-03-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('fd45f6a2-6729-50e1-9e10-639389ad315e', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2025-04', 1950.00, 0.00, 1950.00,
   1760.00, 0.00, 1760.00,
   '2025-04-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('67486db1-59c9-5b0e-b973-38a83018f590', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2025-05', 1950.00, 0.00, 1950.00,
   1760.00, 0.00, 1760.00,
   '2025-05-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('f88c343f-3ac2-5ec3-b678-745471a77172', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2025-06', 1950.00, 0.00, 1950.00,
   1760.00, 0.00, 1760.00,
   '2025-06-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('731e29b8-7b75-5fda-8803-4d555b5f4f78', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2025-07', 1950.00, 0.00, 1950.00,
   1760.00, 0.00, 1760.00,
   '2025-07-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('702f0878-d7dd-5ff6-92e1-cdec3b06ab79', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2025-08', 1950.00, 0.00, 1950.00,
   1760.00, 0.00, 1760.00,
   '2025-08-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('e61451dc-4123-548a-ad5e-a608cec4d763', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2025-09', 1950.00, 0.00, 1950.00,
   1760.00, 0.00, 1760.00,
   '2025-09-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('ab860938-7394-538d-860f-2828e5bf85e3', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2025-10', 1950.00, 0.00, 1950.00,
   1760.00, 0.00, 1760.00,
   '2025-10-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('bc0a30cc-919b-593c-9c6a-0cb24de22642', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2025-11', 1950.00, 0.00, 1950.00,
   1760.00, 0.00, 1760.00,
   '2025-11-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('c01222bf-0a2d-5528-9bfb-5a5f50dff1bf', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2025-12', 1950.00, 0.00, 1950.00,
   1760.00, 0.00, 1760.00,
   '2025-12-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('57350a76-39ba-5d1d-9828-2e5c692f602e', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2026-01', 1950.00, 0.00, 1950.00,
   1760.00, 0.00, 1760.00,
   '2026-01-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('192c8cb7-0053-5ddc-aac8-b9ff73282942', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2026-02', 1950.00, 0.00, 1950.00,
   1760.00, 0.00, 1760.00,
   '2026-02-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('c35c051b-84d9-56f2-a92f-5ede7fcaf933', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2026-03', 1950.00, 0.00, 1950.00,
   1760.00, 0.00, 1760.00,
   '2026-03-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('11d7e468-4b70-5e57-affb-1c6473652748', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2026-04', 1950.00, 0.00, 1950.00,
   1760.00, 0.00, 1760.00,
   '2026-04-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('8d12f7e0-5c2c-5026-ae6b-a5102839df1d', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2026-05', 1950.00, 0.00, 1950.00,
   1760.00, 0.00, 1760.00,
   '2026-05-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('2801d5bc-49a3-59ce-9023-dcebbbdbe28d', 'f3e18d60-b8e3-5e25-8d5f-4c13b60ab5a8', null, '2026-06', 1950.00, 0.00, 1950.00,
   1760.00, 0.00, 1760.00,
   '2026-06-01', 'Check',
   null, null, 'Arrears notice of 14 Jun 2026.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('310f44bd-766c-5512-9efb-cb45327b2336', 'a87bb235-b069-5909-927e-124509a468d2', null, '2025-02', 2885.00, 2111.99, 773.01,
   0.00, 2111.99, 2111.99,
   null, null,
   'Other', '2025-02-01', 'Letter of 14 Jun 2026. Agency share $2,111.99, tenant share 773.01.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('498d3e20-90f7-5d6a-99c1-8adeaf3a528c', 'a87bb235-b069-5909-927e-124509a468d2', null, '2025-03', 2885.00, 2111.99, 773.01,
   0.00, 2111.99, 2111.99,
   null, null,
   'Other', '2025-03-01', 'Letter of 14 Jun 2026. Agency share $2,111.99, tenant share 773.01.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('ea45b129-4910-5184-97fc-6939e16d798b', 'a87bb235-b069-5909-927e-124509a468d2', null, '2025-04', 2885.00, 2111.99, 773.01,
   773.01, 2111.99, 2885.00,
   '2025-04-01', 'Check',
   'Other', '2025-04-01', 'Letter of 14 Jun 2026. Agency share $2,111.99, tenant share 773.01.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('91a1f0d1-7e57-526f-afdc-5ec5147e32ef', 'a87bb235-b069-5909-927e-124509a468d2', null, '2025-05', 2885.00, 1686.61, 1198.39,
   600.00, 1686.61, 2286.61,
   '2025-05-01', 'Check',
   'Other', '2025-05-01', 'Letter of 14 Jun 2026. Agency share $1,686.61, tenant share 1,198.39.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('e964d3c6-4474-577d-bfb2-3150c54f8523', 'a87bb235-b069-5909-927e-124509a468d2', null, '2025-06', 2885.00, 1686.61, 1198.39,
   600.00, 1686.61, 2286.61,
   '2025-06-01', 'Check',
   'Other', '2025-06-01', 'Letter of 14 Jun 2026. Agency share $1,686.61, tenant share 1,198.39.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('947604db-3f34-55c9-997d-fe0629391dc5', 'a87bb235-b069-5909-927e-124509a468d2', null, '2025-07', 2885.00, 1686.61, 1198.39,
   1100.00, 1686.61, 2786.61,
   '2025-07-01', 'Check',
   'Other', '2025-07-01', 'Letter of 14 Jun 2026. Agency share $1,686.61, tenant share 1,198.39.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('1f3cd6a7-ed1f-5144-8992-d29bc104a26c', 'a87bb235-b069-5909-927e-124509a468d2', null, '2025-08', 2885.00, 1686.61, 1198.39,
   600.00, 1686.61, 2286.61,
   '2025-08-01', 'Check',
   'Other', '2025-08-01', 'Letter of 14 Jun 2026. Agency share $1,686.61, tenant share 1,198.39.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('5e8e98dc-89d6-5a41-becc-091c1b29bafb', 'a87bb235-b069-5909-927e-124509a468d2', null, '2025-09', 2885.00, 1686.61, 1198.39,
   0.00, 1686.61, 1686.61,
   null, null,
   'Other', '2025-09-01', 'Letter of 14 Jun 2026. Agency share $1,686.61, tenant share 1,198.39.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('7b6bf27b-14b2-5030-bce3-9ae1655ce5bb', 'a87bb235-b069-5909-927e-124509a468d2', null, '2025-10', 2885.00, 1686.61, 1198.39,
   300.00, 1686.61, 1986.61,
   '2025-10-01', 'Check',
   'Other', '2025-10-01', 'Letter of 14 Jun 2026. Agency share $1,686.61, tenant share 1,198.39.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('c56838fa-6059-5eaa-a5ff-8fdbb7d98193', 'a87bb235-b069-5909-927e-124509a468d2', null, '2025-11', 2885.00, 1686.61, 1198.39,
   0.00, 1686.61, 1686.61,
   null, null,
   'Other', '2025-11-01', 'Letter of 14 Jun 2026. Agency share $1,686.61, tenant share 1,198.39.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('7b7eb898-ed89-5fcd-839a-5908d3ebe927', 'a87bb235-b069-5909-927e-124509a468d2', null, '2025-12', 2885.00, 1686.61, 1198.39,
   400.00, 1686.61, 2086.61,
   '2025-12-01', 'Check',
   'Other', '2025-12-01', 'Letter of 14 Jun 2026. Agency share $1,686.61, tenant share 1,198.39.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('604db806-8331-56a4-83f4-d0370d0610e4', 'a87bb235-b069-5909-927e-124509a468d2', null, '2026-01', 2885.00, 1686.61, 1198.39,
   0.00, 1686.61, 1686.61,
   null, null,
   'Other', '2026-01-01', 'Letter of 14 Jun 2026. Agency share $1,686.61, tenant share 1,198.39.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('9028f287-5f24-5742-8467-605210234220', 'a87bb235-b069-5909-927e-124509a468d2', null, '2026-02', 2885.00, 1686.61, 1198.39,
   0.00, 1686.61, 1686.61,
   null, null,
   'Other', '2026-02-01', 'Letter of 14 Jun 2026. Agency share $1,686.61, tenant share 1,198.39.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('4c90f64f-f20e-5527-a442-0f5d2111b440', 'a87bb235-b069-5909-927e-124509a468d2', null, '2026-03', 2885.00, 1686.61, 1198.39,
   0.00, 1686.61, 1686.61,
   null, null,
   'Other', '2026-03-01', 'Letter of 14 Jun 2026. Agency share $1,686.61, tenant share 1,198.39.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('d338a206-57ce-53ae-bdd7-9b4f35a670f9', 'a87bb235-b069-5909-927e-124509a468d2', null, '2026-04', 2885.00, 1686.61, 1198.39,
   0.00, 1686.61, 1686.61,
   null, null,
   'Other', '2026-04-01', 'Letter of 14 Jun 2026. Agency share $1,686.61, tenant share 1,198.39.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('8920d57e-1899-5610-9e5c-fc9914076be1', 'a87bb235-b069-5909-927e-124509a468d2', null, '2026-05', 2885.00, 1686.61, 1198.39,
   400.00, 1686.61, 2086.61,
   '2026-05-01', 'Check',
   'Other', '2026-05-01', 'Letter of 14 Jun 2026. Agency share $1,686.61, tenant share 1,198.39.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;
insert into public.rent_payments (id, unit_id, lease_id, period, amount_due, govt_due, tenant_due,
    tenant_paid, govt_paid, amount_paid, paid_date, method, govt_program, govt_paid_date, note) values
  ('a4e6d4ee-67c3-5d31-96f4-ce348c972b33', 'a87bb235-b069-5909-927e-124509a468d2', null, '2026-06', 2885.00, 1686.61, 1198.39,
   0.00, 1686.61, 1686.61,
   null, null,
   'Other', '2026-06-01', 'Letter of 14 Jun 2026. Agency share $1,686.61, tenant share 1,198.39.')
on conflict (id) do update set amount_due=excluded.amount_due, govt_due=excluded.govt_due,
  tenant_due=excluded.tenant_due, tenant_paid=excluded.tenant_paid, govt_paid=excluded.govt_paid,
  amount_paid=excluded.amount_paid, lease_id=null, note=excluded.note;

-- ------------------------------ running costs, from the income & expense sheets
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('2c3740a3-27c0-5bdb-9cbb-abe79e5b80d8', (select id from public.buildings where name = '1403 Fulton Street'), 'Maintenance', 715.00, 8580.00, 'operating', false,
   null, 10)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('2f7b727a-3384-5698-8d16-31a60c9cb82d', (select id from public.buildings where name = '1403 Fulton Street'), 'Snow removal', 300.00, 900.00, 'operating', true,
   '$300 in December, January and February only', 20)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('00e23a52-b653-50a2-98fd-0cd759607b7d', (select id from public.buildings where name = '1403 Fulton Street'), 'Garbage', 617.00, 7404.00, 'operating', false,
   null, 30)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('bdd7adfb-0c4e-5d73-b419-0a9bdbe71a63', (select id from public.buildings where name = '1403 Fulton Street'), 'Gas', 750.00, 9000.00, 'operating', false,
   null, 40)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('e2c6e96c-0583-5acc-b16d-e010f9d0cc7c', (select id from public.buildings where name = '1403 Fulton Street'), 'Electricity', 167.00, 2004.00, 'operating', false,
   null, 50)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('e90f8e8f-a489-530d-aded-44a9880da436', (select id from public.buildings where name = '1403 Fulton Street'), 'Water / sewer', 1000.00, 12000.00, 'operating', false,
   null, 60)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('7e8bcbcd-c516-5357-9543-4e7ae46725e9', (select id from public.buildings where name = '1403 Fulton Street'), 'Management fees', 200.00, 2400.00, 'operating', false,
   null, 70)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('bb52bd74-f9db-5b8f-bbad-f5e18fed97bb', (select id from public.buildings where name = '1403 Fulton Street'), 'Professional services', 150.00, 1800.00, 'operating', false,
   null, 80)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('b74ae260-fc1c-53f7-9985-c7f0b373224a', (select id from public.buildings where name = '1403 Fulton Street'), 'Insurance', 924.00, 11088.00, 'operating', false,
   null, 90)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('40ccc054-d972-5fc1-b9c0-d7ff03f62afa', (select id from public.buildings where name = '1403 Fulton Street'), 'Pest control', 100.00, 1200.00, 'operating', false,
   null, 100)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('ff5af116-042f-5be3-8a57-d820c343ec2d', (select id from public.buildings where name = '1403 Fulton Street'), 'Real estate taxes', 3339.67, 40076.00, 'tax', false,
   null, 200)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('5f53cf82-1bb8-59ad-a674-2359af788530', (select id from public.buildings where name = '1403 Fulton Street'), 'Mortgage interest', 1813.66, 21764.00, 'debt', false,
   null, 210)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('7eedebc2-91c6-5e57-b225-605a700a0c14', (select id from public.buildings where name = '1403 Fulton Street'), 'Mortgage payment', 13882.00, 166584.00, 'debt', false,
   null, 220)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;

insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('a2ce7cf9-615f-5254-a5c7-3c7d5dd119e5', (select id from public.buildings where name = '2165 Pacific Street'), 'Maintenance', 302.50, 3630.00, 'operating', false,
   null, 10)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('0e31bbdf-e345-53b6-8b4e-95b39512414b', (select id from public.buildings where name = '2165 Pacific Street'), 'Snow removal', 300.00, 900.00, 'operating', true,
   '$300 in December, January and February only', 20)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('ae55e045-6fcb-5bd4-9c0a-6345cf8edabd', (select id from public.buildings where name = '2165 Pacific Street'), 'Garbage', 500.00, 6000.00, 'operating', false,
   null, 30)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('260362f6-2bb6-5c09-a458-f7219b34eea8', (select id from public.buildings where name = '2165 Pacific Street'), 'Gas', 775.00, 9300.00, 'operating', false,
   null, 40)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('bdf0ec7a-79c2-5b01-89f2-4e153691fe1c', (select id from public.buildings where name = '2165 Pacific Street'), 'Electricity', 70.00, 840.00, 'operating', false,
   null, 50)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('202fbb17-83d3-5da6-b091-3ef2aa7886f3', (select id from public.buildings where name = '2165 Pacific Street'), 'Water / sewer', 750.00, 9000.00, 'operating', false,
   null, 60)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('ae53cf2f-2708-5a66-b92b-da45a495f7fd', (select id from public.buildings where name = '2165 Pacific Street'), 'Management fees', 200.00, 2400.00, 'operating', false,
   null, 70)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('25c97ee4-cc3b-5105-a6e4-1fda61336b5c', (select id from public.buildings where name = '2165 Pacific Street'), 'Professional services', 150.00, 1800.00, 'operating', false,
   null, 80)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('8535ced0-d02e-5d97-b4dc-383ebb804c5e', (select id from public.buildings where name = '2165 Pacific Street'), 'Insurance', 958.00, 11496.00, 'operating', false,
   null, 90)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('1ceb423c-6b63-5832-ac63-b849477eacfd', (select id from public.buildings where name = '2165 Pacific Street'), 'Pest control', 100.00, 1200.00, 'operating', false,
   null, 100)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('086e15f3-8bc0-56d4-bd71-3c639f5f5fa9', (select id from public.buildings where name = '2165 Pacific Street'), 'Painting', 0.00, 3500.00, 'operating', false,
   'Annual figure only on the sheet', 110)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('6870814f-8544-55a8-b97c-88745946bd7c', (select id from public.buildings where name = '2165 Pacific Street'), 'Appliances', 0.00, 600.00, 'operating', false,
   'Annual figure only on the sheet', 120)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('c39b91f4-d490-52b3-ad66-728e7c2b6806', (select id from public.buildings where name = '2165 Pacific Street'), 'Real estate taxes', 1204.60, 14455.22, 'tax', false,
   null, 200)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('b5a3666c-a925-5ea4-9c41-58cfdbf760e8', (select id from public.buildings where name = '2165 Pacific Street'), 'Mortgage interest', 2430.72, 29160.00, 'debt', false,
   null, 210)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;
insert into public.building_expenses (id, building_id, category, monthly_amount, annual_amount,
    kind, seasonal, note, sort_order) values
  ('fb4b6aae-f80a-5880-9402-b307c9acd24f', (select id from public.buildings where name = '2165 Pacific Street'), 'Mortgage payment', 6884.00, 82608.00, 'debt', false,
   null, 220)
on conflict (id) do update set monthly_amount=excluded.monthly_amount,
  annual_amount=excluded.annual_amount, kind=excluded.kind, note=excluded.note;

commit;

-- ============================================================================
--  STILL TO COME, and deliberately left empty
--    * Lease start and end dates for every unit except the Deli.
--    * Tenant names for 2A-2D, 3A, 3B, 3D, 4B-4D at Fulton and all of Pacific
--      except 3F.
--    * The vet clinic's tax arrears — held back until the figures are confirmed.
--    * Which programme pays Shamani Salum's agency share.
--
--  A NOTE ON ONE FIGURE
--  The 1403 Fulton income sheet prints a monthly rent roll of $15,614.55.
--  That is 2165 Pacific's total, pasted into the wrong sheet. Fulton's own
--  units add to $28,761 a month, and its annual figure of $345,151 agrees.
-- ============================================================================
