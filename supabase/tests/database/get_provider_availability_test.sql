-- create extension pgtap if not exists this alread exists no need to add it 
-- create extension if not exists pgtap;

-- Wrap all changes in a transaction so data is rolled back after tests
begin;

-- Plan: we are running 4 assertions across two sections
select plan(4);

-- Test data --------------------------------------------------------------
-- Static UUIDs for test isolation
with
    const as (
        select
            -- Use a real creator id that exists in seed data so we don't have to create dummy auth.users rows
            'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::uuid as provider_id,
            '22222222-2222-2222-2222-222222222222'::uuid as purchase_id,
            -- Pick the first service that belongs to this provider so FK constraints are satisfied
            (select s.id from public.services s
               join public.posts p on p.id = s.post_id
              where p.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::uuid
              limit 1) as service_id,
            '55555555-5555-5555-5555-555555555555'::uuid as appointment_id
    )

-- Ensure the provider has Monday availability 09:00-17:00. If a row already exists, update it.
insert into public.availability (user_id,day,is_active,start_time,end_time)
select provider_id,'monday',true,'09:00','17:00' from const
on conflict (user_id,day) do update
set is_active = excluded.is_active,
    start_time = excluded.start_time,
    end_time   = excluded.end_time;

-- Insert a purchase & appointment at 10:00 on Monday 2025-09-01
with const as (
    select
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::uuid as provider_id,
        '22222222-2222-2222-2222-222222222222'::uuid as purchase_id,
        (select s.id from public.services s
            join public.posts p on p.id = s.post_id
           where p.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::uuid
           limit 1) as service_id,
        '55555555-5555-5555-5555-555555555555'::uuid as appointment_id
)
insert into public.purchases (id,user_id,owner_id,amount,currency,payment_status,service_id,purchase_type)
select purchase_id,provider_id,provider_id,0,'USD','completed',service_id,'appointment' from const;

with const as (
    select
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::uuid as provider_id,
        '22222222-2222-2222-2222-222222222222'::uuid as purchase_id,
        (select s.id from public.services s
            join public.posts p on p.id = s.post_id
           where p.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::uuid
           limit 1) as service_id,
        '55555555-5555-5555-5555-555555555555'::uuid as appointment_id
)
insert into public.appointment_purchases (id,purchase_id,service_id,appointment_date,duration,method,service_type,status)
select appointment_id,purchase_id,service_id,'2025-09-01 10:00+00'::timestamptz,1,'video','consultation','confirmed' from const;

-- Query provider availability for 2025-09-01
with avail as (
    select jsonb_array_elements(available_slots) as slot
    from public.get_provider_availability('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11','2025-09-01','2025-09-01')
),
counts as (
    select
      count(*) filter (where (slot->>'available')::boolean)  as available_cnt,
      count(*) filter (where not (slot->>'available')::boolean) as unavailable_cnt
    from avail
)
select is(
    (select unavailable_cnt > 0 from counts),
    true,
    'Synthetic date: at least one slot is unavailable'
);

select is(
    (with avail as (
        select jsonb_array_elements(available_slots) as slot
        from public.get_provider_availability('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11','2025-09-01','2025-09-01')
    ), counts as (
        select
          count(*) filter (where (slot->>'available')::boolean)  as available_cnt
        from avail
    ) select available_cnt > 0 from counts),
    true,
    'Synthetic date: at least one slot is available'
);

-- ------------------------------------------------------------------
-- Real data smoke-test for creator a0eebc99-… (should already exist)
-- ------------------------------------------------------------------
-- Removed duplicate plan

-- Query live provider availability for a single date that we know has a confirmed appointment at 23:00
with live_avail as (
    select jsonb_array_elements(available_slots) as slot
    from public.get_provider_availability('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11','2025-06-17','2025-06-17')
),
live_counts as (
    select
      count(*) filter (where not (slot->>'available')::boolean) as unavailable_cnt
    from live_avail
)
select is(
    (select unavailable_cnt > 0 from live_counts),
    true,
    'Live data: at least one slot is unavailable'
);

select is(
    (with live_avail as (
        select jsonb_array_elements(available_slots) as slot
        from public.get_provider_availability('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11','2025-06-17','2025-06-17')
    ), live_counts as (
        select
          count(*) filter (where (slot->>'available')::boolean) as available_cnt
        from live_avail
    ) select available_cnt > 0 from live_counts),
    true,
    'Live data: some other slots are still available'
);

-- finish the second plan
select * from finish();
rollback; 

