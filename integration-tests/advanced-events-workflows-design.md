# Advanced Events System Workflows Design

## Overview

This document defines the advanced scenarios for the events system that need to be implemented and tested:

1. **Event Cancellation/Deletion Workflows**
2. **Booking Cancellations and Refunds**
3. **Waitlist System for Sold-out Events**

## 🎯 **Current State Analysis**

### ✅ **What EXISTS in Database:**

1. **`update_event_purchase_status()`** - Can change payment status to `'refunded'` and updates booking status to `'cancelled'`
2. **`waitlist_entries` table** - Has event_id and event_date_id columns for events waitlist
3. **`add_to_waitlist()` function** - Can add users to event waitlists
4. **Event booking statuses**: `'confirmed'`, `'pending'`, `'cancelled'`, `'attended'`
5. **Payment statuses**: `'completed'`, `'pending'`, `'refunded'`, `'failed'`
6. **Appointment cancellation example** - `cancel_appointment_request()` shows refund logic patterns

### ❓ **What NEEDS to be Implemented:**

1. **Event-specific cancellation functions**
2. **Credit refund logic for cancelled bookings**
3. **Event creator cancellation workflows**
4. **Waitlist promotion automation**
5. **Notification systems for cancellations/waitlist**

---

## 1. 🎫 **Event Booking Cancellation Workflows**

### **1.1 User-Initiated Booking Cancellation**

#### **Function: `cancel_event_booking()`**

**Purpose**: Allow attendees to cancel their event bookings with appropriate refund logic

**Parameters**:

```sql
cancel_event_booking(
  p_booking_id UUID,
  p_reason TEXT DEFAULT NULL,
  p_minimum_hours_before INTEGER DEFAULT 24
) RETURNS JSONB
```

**Business Logic**:

1. **Permission Check**: Only booking owner or event creator can cancel
2. **Time-based Refund Policy**:
   - `>= 24 hours before`: Full refund
   - `< 24 hours before`: No refund (configurable)
   - Event creator cancellation: Always full refund
3. **Payment Method Handling**:
   - **Cash purchases**: Refund to payment method
   - **Credit purchases**: Return credits to package
4. **Status Updates**:
   - Booking: `confirmed` → `cancelled`
   - Purchase: `completed` → `refunded` (if applicable)
5. **Waitlist Processing**: Notify next person in waitlist
6. **Capacity Updates**: Make ticket available again

#### **Expected Returns**:

```json
{
  "booking_id": "uuid",
  "status": "cancelled",
  "refund_type": "cash|credits|none",
  "refund_amount": 0,
  "credits_returned": 1,
  "hours_until_event": 48.5,
  "waitlist_notified": true,
  "message": "Booking cancelled. Full refund will be processed."
}
```

### **1.2 Credit-Based Booking Cancellation**

#### **Special Considerations**:

- Credits should be returned to the original package
- Package expiration dates need to be respected
- Usage tracking records need to be updated/reversed

### **1.3 Refund Processing Logic**

#### **Time-Based Policy**:

```javascript
const refundPolicy = {
  more_than_24h: { cash: "full", credits: "full" },
  less_than_24h: { cash: "none", credits: "none" },
  creator_initiated: { cash: "full", credits: "full" },
};
```

---

## 2. 🎭 **Event Cancellation/Deletion Workflows**

### **2.1 Event Creator Cancellation**

#### **Function: `cancel_event()`**

**Purpose**: Allow event creators to cancel entire events

**Parameters**:

```sql
cancel_event(
  p_event_id UUID,
  p_reason TEXT,
  p_refund_policy TEXT DEFAULT 'full' -- 'full', 'partial', 'none'
) RETURNS JSONB
```

**Business Logic**:

1. **Permission Check**: Only event creator or admin
2. **Event Status Update**: Set event status (via post status) to `'archived'`
3. **Booking Processing**:
   - Cancel all confirmed bookings
   - Process refunds based on policy
   - Return credits for credit-based bookings
4. **Waitlist Handling**: Cancel all waitlist entries
5. **Notification System**: Notify all attendees and waitlist users

#### **Cascading Effects**:

- All `event_bookings` → `'cancelled'`
- All `purchases` for this event → `'refunded'` (if policy allows)
- All `waitlist_entries` → `'cancelled'`
- Email notifications to all affected users

### **2.2 Event Deletion (Hard Delete)**

#### **Function: `delete_event()`**

**Purpose**: Permanently remove events (admin only, or events with no bookings)

**Constraints**:

- Cannot delete events with existing bookings (must cancel first)
- Can only delete draft events or events with all bookings cancelled
- Cascades to remove dates, tickets, live rooms

---

## 3. 📝 **Waitlist System for Sold-out Events**

### **3.1 Current Waitlist Infrastructure** ✅

```sql
-- EXISTING TABLE
waitlist_entries (
  id, user_id, email,
  event_id, event_date_id, -- Event-specific fields
  position, status, -- 'waiting', 'notified', 'claimed', 'expired', 'declined'
  last_notified_at, notification_count,
  claim_expires_at, metadata
)
```

### **3.2 Automatic Waitlist Promotion**

#### **Function: `process_event_waitlist()`**

**Purpose**: Automatically promote waitlist users when spots become available

**Trigger Scenarios**:

1. User cancels booking → Promote next waitlist user
2. Ticket capacity increased → Promote multiple users
3. Admin manually processes waitlist

**Business Logic**:

1. **Find Available Spots**: Check actual vs booked capacity
2. **Get Next Waitlist User**: Ordered by position
3. **Send Notification**: Email/push with claim window (24h default)
4. **Update Status**: `'waiting'` → `'notified'`
5. **Set Expiration**: Auto-expire if not claimed

### **3.3 Waitlist Claim Process**

#### **Function: `claim_waitlist_spot()`**

**Purpose**: Allow notified users to claim their waitlist spot

**Parameters**:

```sql
claim_waitlist_spot(
  p_waitlist_id UUID,
  p_payment_method TEXT DEFAULT 'stripe',
  p_use_credits BOOLEAN DEFAULT FALSE,
  p_package_purchase_id UUID DEFAULT NULL
) RETURNS JSONB
```

**Business Logic**:

1. **Validate Claim Window**: Check if claim_expires_at > now()
2. **Check Availability**: Ensure spot is still available
3. **Process Payment/Credits**: Same as normal booking
4. **Update Waitlist**: `'notified'` → `'claimed'`
5. **Create Booking**: Standard event booking process

### **3.4 Waitlist Expiration Handling**

#### **Function: `expire_waitlist_claims()`**

**Purpose**: Automatically expire unclaimed waitlist notifications

**Trigger**: Scheduled job or manual call

**Business Logic**:

1. **Find Expired Claims**: `claim_expires_at` < now() AND status = 'notified'
2. **Update Status**: `'notified'` → `'expired'`
3. **Promote Next User**: Continue down the waitlist
4. **Notification**: Inform about missed opportunity

---

## 4. 🔄 **Integration Points**

### **4.1 Universal Credits Integration**

#### **Credit Return Logic**:

```sql
-- When cancelling credit-based booking
UPDATE universal_package_purchases
SET event_credits_remaining = event_credits_remaining + p_credits_to_return
WHERE id = p_package_purchase_id;

-- Update usage tracking
UPDATE package_usage_tracking
SET status = 'refunded', refunded_at = now()
WHERE booking_id = p_booking_id;
```

### **4.2 Notification System Integration**

#### **Notification Types**:

- `'booking_cancelled'` - User cancelled their booking
- `'event_cancelled'` - Creator cancelled entire event
- `'waitlist_promoted'` - User promoted from waitlist
- `'waitlist_expired'` - User missed claim window
- `'refund_processed'` - Refund completed

### **4.3 Payment System Integration**

#### **Refund Processing**:

- **Stripe Integration**: Process actual refunds for cash payments
- **Credit Returns**: Return credits to packages
- **Partial Refunds**: Handle percentage-based refunds

---

## 5. 🧪 **Testing Strategy**

### **5.1 High Priority Test Scenarios**

#### **Booking Cancellation Tests**:

1. ✅ User cancels booking > 24h before (full refund)
2. ✅ User cancels booking < 24h before (no refund)
3. ✅ Creator cancels user booking (full refund)
4. ✅ Credit-based booking cancellation (credits returned)
5. ✅ Cash booking cancellation (payment refunded)
6. ✅ Cancellation triggers waitlist promotion

#### **Event Cancellation Tests**:

1. ✅ Creator cancels event (all bookings refunded)
2. ✅ Creator deletes draft event (no bookings)
3. ❌ Admin tries to delete event with bookings (should fail)
4. ✅ Event cancellation notifies all attendees

#### **Waitlist Tests**:

1. ✅ Auto-add to waitlist when event sold out
2. ✅ Promote user when spot becomes available
3. ✅ Claim waitlist spot within time window
4. ✅ Expire unclaimed waitlist notifications
5. ✅ Process multiple waitlist promotions

### **5.2 Edge Cases to Test**

1. **Concurrent Operations**: Multiple users cancelling simultaneously
2. **Expired Packages**: Returning credits to expired packages
3. **Partial Refunds**: Event creator sets partial refund policy
4. **Invalid Claims**: User tries to claim expired waitlist spot
5. **Capacity Changes**: Creator increases capacity while waitlist exists

### **5.3 Data Integrity Tests**

1. **Orphaned Records**: Ensure no dangling bookings after event deletion
2. **Capacity Consistency**: Booking counts match actual capacity
3. **Credit Balance**: Package credits balance correctly after cancellations
4. **Status Transitions**: Proper state machine for booking/event statuses

---

## 6. 📋 **Implementation Priority**

### **Phase 1: Basic Cancellation** (High Priority)

- [ ] `cancel_event_booking()` function
- [ ] Basic refund logic (cash vs credits)
- [ ] Booking status updates
- [ ] Integration tests for cancellation flows

### **Phase 2: Event Management** (Medium Priority)

- [ ] `cancel_event()` function
- [ ] `delete_event()` function
- [ ] Bulk refund processing
- [ ] Event creator permissions

### **Phase 3: Waitlist Automation** (Medium Priority)

- [ ] `process_event_waitlist()` function
- [ ] `claim_waitlist_spot()` function
- [ ] Automatic promotion logic
- [ ] Expiration handling

### **Phase 4: Advanced Features** (Low Priority)

- [ ] Partial refund policies
- [ ] Complex notification rules
- [ ] Analytics and reporting
- [ ] Admin override functions

---

## 7. 🎯 **Success Criteria**

### **Functional Requirements**:

- ✅ Users can cancel bookings with appropriate refunds
- ✅ Event creators can cancel/delete events
- ✅ Waitlist users are automatically promoted
- ✅ Credits are correctly returned for cancelled bookings
- ✅ All status transitions are handled properly

### **Non-Functional Requirements**:

- ✅ Cancellation processing < 2 seconds
- ✅ Waitlist promotion < 30 seconds
- ✅ Data consistency maintained under concurrent operations
- ✅ All operations are properly logged and auditable

### **Test Coverage**:

- ✅ 100% coverage of cancellation business logic
- ✅ All edge cases tested (expired claims, concurrent cancellations)
- ✅ Integration tests with payment and credit systems
- ✅ Performance tests under load

This design provides a comprehensive foundation for implementing and testing advanced event system workflows with proper refund handling, waitlist management, and event lifecycle management.


