# Stripe Integration Plan

## Overview

This document outlines the integration of Stripe with our purchase system to handle various types of transactions:

- On-demand content purchases
- Event bookings
- Service appointments
- Creator subscriptions (tiered)

## System Architecture

### Core Components

1. **Frontend Payment Flow**: Client-side Stripe Elements/Checkout integration
2. **Stripe Webhook Handler**: Server endpoint to process Stripe events
3. **Access Control System**: Verify user access to content based on purchases/subscriptions
4. **Subscription Management**: Handle subscription lifecycle and access tiers

### Data Flow

1. User initiates purchase → Frontend creates Stripe payment intent with metadata
2. User completes payment → Stripe sends webhook event
3. Backend processes webhook → Updates database → Grants appropriate access

## Webhook Integration

### Webhook Events to Handle

- `payment_intent.succeeded`: Completed one-time purchases
- `invoice.paid`: Successful subscription payments
- `invoice.payment_failed`: Failed subscription payments
- `customer.subscription.created`: New subscription
- `customer.subscription.updated`: Subscription changes
- `customer.subscription.deleted`: Subscription cancellations

### Required Metadata for Each Purchase Type

All purchases need to include metadata in the Stripe payment intent/subscription:

#### Content Purchase

```json
{
  "purchase_type": "content",
  "content_id": "<UUID>",
  "post_id": "<UUID>",
  "owner_id": "<UUID>"
}
```

#### Event Booking

```json
{
  "purchase_type": "event",
  "event_id": "<UUID>",
  "post_id": "<UUID>",
  "date_id": "<UUID>",
  "ticket_id": "<UUID>",
  "owner_id": "<UUID>",
  "attendees": 1
}
```

#### Service Appointment

```json
{
  "purchase_type": "appointment",
  "service_id": "<UUID>",
  "post_id": "<UUID>",
  "owner_id": "<UUID>",
  "appointment_date": "ISO-8601-timestamp",
  "duration": 60
}
```

#### Subscription

```json
{
  "purchase_type": "subscription",
  "owner_id": "<UUID>",
  "tier": "basic|premium|unlimited",
  "plan_name": "Monthly Plan"
}
```

## Content Access Control

### On-Demand Content Access

1. Update `content_purchases` and `protected_media_data` relationship:

   - When purchase is successful, create entry in `content_purchases`
   - User can access `protected_media_data.url` if they have an entry in `content_purchases`

2. Create functions for content access verification:
   ```sql
   CREATE OR REPLACE FUNCTION can_access_content(content_id UUID)
   RETURNS BOOLEAN AS $$
   BEGIN
     RETURN EXISTS (
       SELECT 1
       FROM content_purchases cp
       JOIN purchases p ON cp.purchase_id = p.id
       WHERE cp.content_id = $1
       AND p.user_id = auth.uid()
       AND p.payment_status = 'completed'
       AND (cp.access_expires_at IS NULL OR cp.access_expires_at > NOW())
     )
     OR
     EXISTS (
       -- Check if user has subscription access
       SELECT 1
       FROM subscriptions s
       JOIN purchases p ON s.purchase_id = p.id
       JOIN posts post ON post.user_id = p.owner_id
       JOIN on_demand_media odm ON odm.post_id = post.id
       WHERE odm.id = $1
       AND p.user_id = auth.uid()
       AND s.status IN ('active', 'trial')
       -- This would need a join to subscription_content_access table (to be created)
       AND EXISTS (
         SELECT 1 FROM subscription_content_access
         WHERE subscription_tier = s.tier
         AND content_id = $1
       )
     );
   END;
   $$ LANGUAGE plpgsql SECURITY DEFINER;
   ```

### Event Booking Access

1. Use `event_bookings` to determine if user has access to an event
2. Create function for event access verification:
   ```sql
   CREATE OR REPLACE FUNCTION can_access_event(event_id UUID, date_id UUID)
   RETURNS BOOLEAN AS $$
   BEGIN
     RETURN EXISTS (
       SELECT 1
       FROM event_bookings eb
       JOIN purchases p ON eb.purchase_id = p.id
       WHERE eb.event_id = $1
       AND eb.date_id = $2
       AND p.user_id = auth.uid()
       AND p.payment_status = 'completed'
       AND eb.status IN ('confirmed', 'pending', 'attended')
     );
   END;
   $$ LANGUAGE plpgsql SECURITY DEFINER;
   ```

### Appointment Access

1. Use `appointment_purchases` to determine if user has booked an appointment
2. Create function for appointment verification:
   ```sql
   CREATE OR REPLACE FUNCTION can_access_appointment(service_id UUID, appointment_date TIMESTAMP WITH TIME ZONE)
   RETURNS BOOLEAN AS $$
   BEGIN
     RETURN EXISTS (
       SELECT 1
       FROM appointment_purchases ap
       JOIN purchases p ON ap.purchase_id = p.id
       WHERE ap.service_id = $1
       AND ap.appointment_date = $2
       AND p.user_id = auth.uid()
       AND p.payment_status = 'completed'
       AND ap.status IN ('confirmed', 'pending', 'completed')
     );
   END;
   $$ LANGUAGE plpgsql SECURITY DEFINER;
   ```

## Subscription Management

### Tiered Access

1. Create a new table to define subscription tiers and content access:

   ```sql
   CREATE TABLE subscription_content_access (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
     content_id UUID REFERENCES on_demand_media(id) ON DELETE CASCADE,
     post_type TEXT NOT NULL, -- Type of content this applies to (all, article, video, etc.)
     subscription_tier TEXT NOT NULL CHECK (subscription_tier IN ('basic', 'premium', 'unlimited')),
     created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
     UNIQUE (creator_id, content_id, subscription_tier)
   );
   ```

2. Creator settings for subscription tiers:

   ```sql
   CREATE TABLE creator_subscription_tiers (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
     tier TEXT NOT NULL CHECK (tier IN ('basic', 'premium', 'unlimited')),
     name TEXT NOT NULL,
     description TEXT,
     price_monthly NUMERIC(10, 2) NOT NULL,
     price_quarterly NUMERIC(10, 2),
     price_annual NUMERIC(10, 2),
     stripe_price_id_monthly TEXT,
     stripe_price_id_quarterly TEXT,
     stripe_price_id_annual TEXT,
     benefits JSONB,
     is_active BOOLEAN DEFAULT true,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
     UNIQUE (creator_id, tier)
   );
   ```

3. Functions for subscription access checks:

   ```sql
   CREATE OR REPLACE FUNCTION has_active_subscription(creator_id UUID, required_tier TEXT DEFAULT 'basic')
   RETURNS BOOLEAN AS $$
   DECLARE
     tiers TEXT[];
   BEGIN
     -- Map tiers to all tiers that satisfy the required level
     CASE required_tier
       WHEN 'basic' THEN tiers := ARRAY['basic', 'premium', 'unlimited'];
       WHEN 'premium' THEN tiers := ARRAY['premium', 'unlimited'];
       WHEN 'unlimited' THEN tiers := ARRAY['unlimited'];
     END CASE;

     RETURN EXISTS (
       SELECT 1
       FROM subscriptions s
       JOIN purchases p ON s.purchase_id = p.id
       WHERE p.owner_id = creator_id
       AND p.user_id = auth.uid()
       AND s.status IN ('active', 'trial')
       AND s.tier = ANY(tiers)
     );
   END;
   $$ LANGUAGE plpgsql SECURITY DEFINER;
   ```

### Stripe Sync

1. Process to sync subscription status with Stripe:
   - Scheduled function to call Stripe API for subscription status updates
   - Webhook processing for real-time updates
   - Handle subscription lifecycle events (creation, updates, cancellations)

## Database Changes

### New Tables

1. `subscription_content_access`: Maps content to subscription tiers
2. `creator_subscription_tiers`: Defines creator's subscription offerings

### Table Modifications

1. Update `purchases` and associated tables as needed for Stripe integration
2. Add Stripe-specific fields to the subscription table

### Additional Functions

1. Create functions for access verification
2. Create support functions for Stripe webhook processing

## Implementation Plan

### Phase 1: Setup & Stripe Integration

1. Create Stripe account and API keys
2. Set up webhook endpoint
3. Implement basic payment flow in frontend

### Phase 2: Purchase Processing

1. Implement webhook handlers for each event type
2. Create database functions for purchase processing
3. Test one-time purchases

### Phase 3: Subscription System

1. Set up subscription products and prices in Stripe
2. Implement subscription management
3. Create tiered access controls

### Phase 4: Testing & Validation

1. Unit tests for each purchase type
2. End-to-end testing
3. Subscription lifecycle testing

## Security Considerations

1. Validate webhook signatures
2. Implement idempotency for webhook processing
3. Secure protected content URLs
4. Audit logging for all payment-related actions
