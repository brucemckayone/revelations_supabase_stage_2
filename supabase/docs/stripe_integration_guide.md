# Stripe Integration Guide for the Purchase System

This guide outlines how to integrate Stripe with the purchase system using webhooks and database functions.

## Prerequisites

1. A Stripe account with API keys
2. Webhook endpoint set up to receive Stripe events
3. Database migration `20250503193000_stripe_subscription_system.sql` applied

## Setting Up Stripe

### 1. Configure Stripe API Keys

Set up your environment with the following Stripe API keys:

```
STRIPE_PUBLIC_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

### 2. Configure Webhook Endpoints

In your Stripe Dashboard:

1. Go to Developers → Webhooks → Add endpoint
2. Set the endpoint URL to your webhook handler
3. Enable the following events:
   - `payment_intent.succeeded`
   - `checkout.session.completed`
   - `invoice.paid`
   - `invoice.payment_failed`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`

## Implementing Webhook Handlers

### 1. Webhook Endpoint Setup

Create a secure endpoint to receive webhook events:

```typescript
// Example Node.js webhook handler
import express from "express";
import { createClient } from "@supabase/supabase-js";
import Stripe from "stripe";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
const app = express();
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

app.post(
  "/stripe-webhook",
  express.raw({ type: "application/json" }),
  async (req, res) => {
    const sig = req.headers["stripe-signature"];

    try {
      // Verify webhook signature
      const event = stripe.webhooks.constructEvent(
        req.body,
        sig,
        process.env.STRIPE_WEBHOOK_SECRET
      );

      // Process the event
      await handleStripeEvent(event);

      res.json({ received: true });
    } catch (err) {
      console.error(`Webhook Error: ${err.message}`);
      res.status(400).send(`Webhook Error: ${err.message}`);
    }
  }
);
```

### 2. Webhook Event Handling

Implement the event handler to process different event types:

```typescript
async function handleStripeEvent(event) {
  // Store event in database for idempotency
  const { data, error } = await supabase
    .from("stripe_webhook_events")
    .insert({
      id: event.id,
      type: event.type,
      object_id: event.data.object.id,
      object_type: event.data.object.object,
      data: event.data,
      processed: false,
    })
    .select()
    .single();

  // If event already exists, it's a duplicate
  if (error && error.code === "23505") {
    console.log(`Duplicate webhook event: ${event.id}`);
    return;
  }

  try {
    // Process based on event type
    switch (event.type) {
      case "payment_intent.succeeded":
        await processPaymentIntentSucceeded(event);
        break;
      case "checkout.session.completed":
        await processCheckoutSessionCompleted(event);
        break;
      case "invoice.paid":
        await processInvoicePaid(event);
        break;
      case "invoice.payment_failed":
        await processInvoicePaymentFailed(event);
        break;
      case "customer.subscription.created":
      case "customer.subscription.updated":
        await processSubscriptionUpdated(event);
        break;
      case "customer.subscription.deleted":
        await processSubscriptionDeleted(event);
        break;
    }

    // Mark as processed
    await supabase
      .from("stripe_webhook_events")
      .update({ processed: true })
      .eq("id", event.id);
  } catch (error) {
    // Log error and update record
    console.error(`Error processing webhook: ${error.message}`);
    await supabase
      .from("stripe_webhook_events")
      .update({
        processed: false,
        processing_error: error.message,
      })
      .eq("id", event.id);
    throw error;
  }
}
```

### 3. Event-Specific Handlers

#### Payment Intent Succeeded (One-time Purchases)

```typescript
async function processPaymentIntentSucceeded(event) {
  const paymentIntent = event.data.object;

  // Call the database function to process the payment
  const { data, error } = await supabase.rpc(
    "process_payment_intent_succeeded",
    {
      payment_intent_id: paymentIntent.id,
      event_data: paymentIntent,
    }
  );

  if (error) {
    throw new Error(`Error processing payment: ${error.message}`);
  }

  console.log(`Payment processed: ${data}`);
}
```

#### Invoice Paid (Subscriptions)

```typescript
async function processInvoicePaid(event) {
  const invoice = event.data.object;

  // For subscriptions, we need to get the subscription details
  if (invoice.subscription) {
    // Call the database function to process the invoice
    const { data, error } = await supabase.rpc("process_invoice_paid", {
      invoice_id: invoice.id,
      event_data: invoice,
    });

    if (error) {
      throw new Error(`Error processing invoice: ${error.message}`);
    }

    console.log(`Invoice processed: ${data}`);
  }
}
```

#### Subscription Updated

```typescript
async function processSubscriptionUpdated(event) {
  const subscription = event.data.object;

  // Call the database function to update the subscription
  const { data, error } = await supabase.rpc("process_subscription_updated", {
    subscription_id: subscription.id,
    event_data: subscription,
  });

  if (error) {
    throw new Error(`Error updating subscription: ${error.message}`);
  }

  console.log(`Subscription updated: ${data}`);
}
```

## Client-Side Integration

### 1. Creating Payment Intents

```typescript
// Example of creating a payment intent for content purchase
async function createContentPurchase(contentId, userId, ownerId, amount) {
  // Create payment intent with metadata
  const response = await fetch("/api/create-payment-intent", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      amount: amount * 100, // convert to cents
      currency: "usd",
      metadata: {
        purchase_type: "content",
        content_id: contentId,
        user_id: userId,
        owner_id: ownerId,
      },
    }),
  });

  const { clientSecret } = await response.json();

  return clientSecret;
}
```

### 2. Creating Subscriptions

```typescript
// Example of creating a subscription
async function createSubscription(tierId, userId, ownerId, priceId) {
  // Get subscription tier details
  const { data: tierData } = await supabase
    .from("creator_subscription_tiers")
    .select("*")
    .eq("id", tierId)
    .single();

  // Create checkout session for subscription
  const response = await fetch("/api/create-subscription", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      price_id: priceId,
      metadata: {
        purchase_type: "subscription",
        user_id: userId,
        owner_id: ownerId,
        tier: tierData.tier_key,
        plan_name: tierData.tier_name,
      },
    }),
  });

  const { sessionId } = await response.json();

  // Redirect to checkout
  const stripe = Stripe(process.env.STRIPE_PUBLIC_KEY);
  stripe.redirectToCheckout({ sessionId });
}
```

## Required Metadata for Each Purchase Type

### Content Purchase

```json
{
  "purchase_type": "content",
  "content_id": "<UUID>",
  "user_id": "<UUID>",
  "owner_id": "<UUID>"
}
```

### Event Booking

```json
{
  "purchase_type": "event",
  "event_id": "<UUID>",
  "date_id": "<UUID>",
  "ticket_id": "<UUID>",
  "user_id": "<UUID>",
  "owner_id": "<UUID>",
  "attendees": 1,
  "is_virtual": false
}
```

### Service Appointment

```json
{
  "purchase_type": "appointment",
  "service_id": "<UUID>",
  "user_id": "<UUID>",
  "owner_id": "<UUID>",
  "appointment_date": "ISO-8601-timestamp",
  "duration": 60,
  "method": "video|phone|in-person",
  "service_type": "reading|healing|coaching|consultation"
}
```

### Subscription

```json
{
  "purchase_type": "subscription",
  "user_id": "<UUID>",
  "owner_id": "<UUID>",
  "tier": "<tier_key>",
  "plan_name": "Monthly Plan"
}
```

## Testing Webhooks

1. Use Stripe CLI for local testing:

   ```
   stripe listen --forward-to localhost:3000/stripe-webhook
   ```

2. Test events with Stripe CLI:

   ```
   stripe trigger payment_intent.succeeded
   stripe trigger invoice.paid
   ```

3. Verify database records after each test event

## Subscription Management

### Managing Subscription Tiers

Creators can define subscription tiers through the `creator_subscription_tiers` table:

```sql
INSERT INTO creator_subscription_tiers (
  creator_id, tier_key, tier_name, description,
  price_monthly, price_quarterly, price_annual,
  stripe_price_id_monthly, stripe_price_id_quarterly, stripe_price_id_annual,
  stripe_product_id, benefits, priority, is_active, trial_days
) VALUES (
  'creator-uuid', 'bronze', 'Bronze Tier', 'Basic access to content',
  9.99, 27.99, 99.99,
  'price_monthly_id', 'price_quarterly_id', 'price_annual_id',
  'prod_id', '{"features": ["Access to basic content", "Weekly newsletter"]}',
  10, true, 7
);
```

### Managing Content Access

Define which subscription tiers have access to which content:

```sql
-- Grant access to specific content for a tier
INSERT INTO subscription_content_access (
  creator_id, content_id, tier_key
) VALUES (
  'creator-uuid', 'content-uuid', 'bronze'
);

-- Grant access to a post type for a tier
INSERT INTO subscription_content_access (
  creator_id, post_type, tier_key
) VALUES (
  'creator-uuid', 'article', 'silver'
);
```

## Troubleshooting

### Common Issues

1. **Duplicate Webhook Events**: Check the `stripe_webhook_events` table for duplicates
2. **Missing Metadata**: Ensure all required metadata is included in payment intents
3. **Subscription Status Issues**: Check the status mapping in the `process_subscription_updated` function

### Debugging

1. Monitor the `stripe_webhook_events` table for unprocessed events
2. Check for errors in the `processing_error` column
3. Use Stripe Dashboard to inspect event details
