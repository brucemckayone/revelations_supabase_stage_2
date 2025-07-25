-- Complete subscription handling functions for webhook integration
-- This migration implements the missing functions referenced in the Stripe webhook

-- Function to handle successful invoice payments
create or replace function process_invoice_paid(event_data jsonb)
returns void as $$
declare
  invoice_id text;
  subscription_id text;
  current_period_start timestamp with time zone;
  current_period_end timestamp with time zone;
  purchase_record record;
begin
  -- Extract invoice details from event data
  invoice_id := event_data->>'id';
  subscription_id := event_data->>'subscription';
  
  if subscription_id is null then
    raise notice 'Invoice % has no subscription, skipping', invoice_id;
    return;
  end if;

  -- Extract period information
  current_period_start := to_timestamp((event_data->'lines'->'data'->0->'period'->>'start')::bigint);
  current_period_end := to_timestamp((event_data->'lines'->'data'->0->'period'->>'end')::bigint);

  -- Find the purchase record
  select * into purchase_record
  from purchases
  where stripe_subscription_id = subscription_id;

  if not found then
    raise notice 'No purchase record found for subscription %', subscription_id;
    return;
  end if;

  -- Update purchase status to completed
  update purchases
  set 
    payment_status = 'completed',
    updated_at = now()
  where id = purchase_record.id;

  -- Update or create subscription record with payment confirmation
  insert into subscriptions (
    purchase_id,
    status,
    current_period_start,
    current_period_end,
    updated_at
  )
  values (
    purchase_record.id,
    'active',
    current_period_start,
    current_period_end,
    now()
  )
  on conflict (purchase_id) do update set
    status = 'active',
    current_period_start = excluded.current_period_start,
    current_period_end = excluded.current_period_end,
    updated_at = now();

  -- For universal package subscriptions, refresh credits
  if purchase_record.purchase_type = 'package' then
    perform refresh_universal_package_credits(purchase_record.id);
  end if;

  raise notice 'Successfully processed invoice payment for subscription %', subscription_id;
end;
$$ language plpgsql security definer;

-- Function to handle failed invoice payments
create or replace function process_invoice_payment_failed(
  invoice_id text,
  subscription_id text,
  invoice_data jsonb
)
returns void as $$
declare
  purchase_record record;
begin
  if subscription_id is null then
    raise notice 'Invoice % has no subscription, skipping', invoice_id;
    return;
  end if;

  -- Find the purchase record
  select * into purchase_record
  from purchases
  where stripe_subscription_id = subscription_id;

  if not found then
    raise notice 'No purchase record found for subscription %', subscription_id;
    return;
  end if;

  -- Update purchase status to failed
  update purchases
  set 
    payment_status = 'failed',
    updated_at = now()
  where id = purchase_record.id;

  -- Update subscription status
  update subscriptions
  set 
    status = 'past_due',
    updated_at = now()
  where purchase_id = purchase_record.id;

  raise notice 'Successfully processed failed invoice payment for subscription %', subscription_id;
end;
$$ language plpgsql security definer;

-- Function to refresh universal package credits (for recurring subscriptions)
create or replace function refresh_universal_package_credits(p_purchase_id uuid)
returns void as $$
declare
  package_purchase record;
  package_info record;
  new_credits integer;
begin
  -- Get the package purchase details
  select * into package_purchase
  from universal_package_purchases
  where purchase_id = p_purchase_id;

  if not found then
    raise notice 'No universal package purchase found for purchase %', p_purchase_id;
    return;
  end if;

  -- Get the package details to know how many credits to add
  select * into package_info
  from universal_packages
  where id = package_purchase.package_id;

  if not found then
    raise notice 'Package % not found', package_purchase.package_id;
    return;
  end if;

  -- For recurring packages, add the full credit amount
  if package_info.package_type = 'recurring' then
    new_credits := package_info.total_credits;
    
    -- Add credits to the package purchase
    update universal_package_purchases
    set 
      event_credits_remaining = event_credits_remaining + new_credits,
      updated_at = now()
    where id = package_purchase.id;

    raise notice 'Added % credits to recurring package purchase %', new_credits, package_purchase.id;
  end if;
end;
$$ language plpgsql security definer;

-- Add comment
comment on function process_invoice_paid(jsonb) is 'Processes successful subscription invoice payments and refreshes credits for recurring packages';
comment on function process_invoice_payment_failed(text, text, jsonb) is 'Handles failed subscription invoice payments';
comment on function refresh_universal_package_credits(uuid) is 'Refreshes credits for recurring universal package subscriptions'; 