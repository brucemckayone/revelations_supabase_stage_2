# Payment & Credits Integration Fix Plan

## 🎯 Executive Summary

The current system has a **sophisticated events ticketing foundation** but critical integration gaps that prevent universal packages and credits from working properly. This plan addresses the missing webhook handlers, credit consumption functions, and subscription processing to create a complete payment ecosystem.

## 🚨 Current Status Analysis

### ✅ What's Working Perfectly

- **Direct Event Ticket Purchases** - Full Stripe integration via `purchase_type = "event"`
- **Event Booking Infrastructure** - Complete database schema and functions
- **Universal Package Data Storage** - Credit tracking tables exist and function
- **Payment Processing Foundation** - Solid webhook infrastructure

### ❌ Critical Issues Found

#### 1. **BROKEN: Universal Package Purchases**

```typescript
// Webhook only handles:
case "content": ✅
case "event": ✅
case "appointment": ✅
// MISSING:
case "package": ❌ // Universal packages fail silently!
```

#### 2. **MISSING: Credit Consumption System**

- ✅ Storage: `event_credits_remaining` tracking works
- ❌ Functions: `book_event_with_credits()` doesn't exist
- ❌ Validation: `can_book_event_with_credits()` doesn't exist

#### 3. **INCOMPLETE: Subscription Processing**

- ✅ Basic webhook handling exists
- ❌ Universal package recurring billing not integrated
- ❌ Credit refresh logic not implemented

## 🏗️ Implementation Plan

### Phase 1: Critical Webhook Fixes 🚨

**Objective:** Fix universal package purchases (currently broken)

#### Task 1.1: Add Package Webhook Handler

**File:** `nextjs/app/api/stripe/webhook/route.ts`

```typescript
// Add to handlePaymentIntentSucceeded():
case "package":
  return processUniversalPackagePurchase(paymentIntent);
```

#### Task 1.2: Implement processUniversalPackagePurchase()

**Location:** Same file, new function

```typescript
async function processUniversalPackagePurchase(
  paymentIntent: Stripe.PaymentIntent
) {
  const { metadata } = paymentIntent;
  const supabase = createAdminClient(await cookies());

  // Find purchase record
  const { data: purchaseData, error: purchaseError } = await supabase
    .from("purchases")
    .select("id")
    .eq("stripe_payment_intent_id", paymentIntent.id)
    .single();

  if (purchaseError || !purchaseData) {
    throw new Error("Universal package purchase not found");
  }

  // Call database function
  const { data: result, error } = await supabase.rpc(
    "process_universal_package_purchase_payment",
    {
      p_purchase_id: purchaseData.id,
      p_payment_intent_id: paymentIntent.id,
      p_package_id: metadata.package_id,
    }
  );

  if (error) {
    throw new Error(`Error processing universal package: ${error.message}`);
  }

  return result;
}
```

#### Task 1.3: Complete Subscription Handlers

**Action:** Uncomment and complete subscription processing in webhook

### Phase 2: Credits Integration System 🎫

**Objective:** Enable booking events with credits

#### Task 2.1: Apply Credits Migration

**File:** `supabase/migrations-templates/20250702000007_universal_credits_events_integration.sql`
**Action:** Apply this migration to add:

- `book_event_with_credits()` function
- `can_book_event_with_credits()` function
- `universal_package_event_usage` table
- Credit consumption logic

#### Task 2.2: Verify Credit Functions

**Functions to implement/verify:**

```sql
-- Check if user can book event with credits
SELECT can_book_event_with_credits(
  p_event_id UUID,
  p_date_id UUID,
  p_ticket_id UUID,
  p_quantity INTEGER
);

-- Book event using credits
SELECT book_event_with_credits(
  p_event_id UUID,
  p_date_id UUID,
  p_ticket_id UUID,
  p_quantity INTEGER,
  p_package_purchase_id UUID
);
```

### Phase 3: Complete Integration Testing 🧪

**Objective:** Ensure all payment flows work correctly

#### Task 3.1: Test Direct Event Purchases

- Verify existing functionality still works
- Test all ticket types and event dates
- Confirm webhook processing

#### Task 3.2: Test Universal Package Purchases

- One-time package purchases
- Recurring package subscriptions
- Credit allocation and tracking

#### Task 3.3: Test Credit Event Booking

- Book events using package credits
- Verify credit deduction
- Test insufficient credits handling

#### Task 3.4: Test Recurring Billing

- Subscription renewal
- Credit refresh on billing cycle
- Failed payment handling

## 📋 Detailed Implementation Checklist

### Critical Path Items (Must Fix First)

- [ ] **1.1** Add `case "package"` to webhook handler
- [ ] **1.2** Implement `processUniversalPackagePurchase()` function
- [ ] **1.3** Test universal package purchase flow
- [ ] **2.1** Apply universal credits migration
- [ ] **2.2** Test `book_event_with_credits()` function

### Integration Items (Core Features)

- [ ] **3.1** Complete subscription webhook handling
- [ ] **3.2** Test recurring package billing
- [ ] **3.3** Implement credit refresh logic
- [ ] **3.4** Test cross-creator package usage

### Validation Items (Quality Assurance)

- [ ] **4.1** Create integration test suite
- [ ] **4.2** Test all payment failure scenarios
- [ ] **4.3** Verify webhook idempotency
- [ ] **4.4** Load test credit consumption
- [ ] **4.5** Security audit of payment flows

## 🔧 Technical Specifications

### Database Changes Required

1. **Apply Migration:** `20250702000007_universal_credits_events_integration.sql`
2. **New Tables:** `universal_package_event_usage`, `universal_package_event_access_rules`
3. **New Functions:** Credit booking and validation functions

### API Changes Required

1. **Webhook Enhancement:** Add package purchase handling
2. **New Endpoints:** Credit balance checking (if needed)
3. **Function Updates:** Enhanced error handling

### Frontend Integration Points

1. **Package Purchase Flow:** Must handle `purchase_type = "package"`
2. **Credit Booking Interface:** New booking flow for credit users
3. **Balance Display:** Show remaining credits to users

## 🧪 Testing Strategy

### Unit Tests

- Individual function testing
- Credit calculation accuracy
- Webhook handler isolation

### Integration Tests

- End-to-end purchase flows
- Cross-system credit usage
- Webhook processing scenarios

### Load Tests

- Concurrent credit usage
- High-volume event booking
- Webhook processing under load

## 📊 Success Metrics

### Functionality Metrics

- [ ] 100% universal package purchases succeed
- [ ] 100% credit event bookings succeed
- [ ] 0% webhook processing failures
- [ ] All subscription renewals work correctly

### Performance Metrics

- Webhook response time < 5 seconds
- Credit booking time < 2 seconds
- Zero payment processing errors

## 🚀 Deployment Plan

### Pre-Deployment

1. Apply database migrations
2. Deploy webhook handler updates
3. Smoke test critical flows

### Deployment

1. Deploy in staging environment
2. Run full integration test suite
3. Deploy to production with monitoring

### Post-Deployment

1. Monitor webhook success rates
2. Track credit usage patterns
3. Validate all payment flows

## 📝 Notes & Considerations

### Security

- Ensure webhook signature validation
- Validate credit consumption authorization
- Audit payment intent metadata

### Scalability

- Credit consumption must be atomic
- Webhook processing should be idempotent
- Consider rate limiting for credit usage

### Monitoring

- Alert on webhook failures
- Track credit consumption patterns
- Monitor subscription renewal success rates

---

## 🎯 Next Steps

1. **START HERE:** Fix webhook package handling (prevents all package purchases)
2. **THEN:** Apply credits migration (enables credit booking)
3. **FINALLY:** Complete testing and monitoring setup

This plan transforms your system from **"Events with broken packages"** to **"Complete payment ecosystem with credits, packages, and subscriptions"**.
