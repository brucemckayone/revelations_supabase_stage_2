# Database Changes Implementation Plan

## 🎯 **Current State Assessment**

### ✅ **What We Have:**

- **Existing event system**: Full CRUD for events, bookings, tickets
- **Payment system**: `update_event_purchase_status()` can set status to 'refunded'
- **Credit system**: Universal packages with credit tracking
- **Waitlist system**: `waitlist_entries` table with event support
- **Appointment cancellation pattern**: `cancel_appointment_request()` as reference

### ❓ **What We're Missing:**

- **Event booking cancellation function**
- **Credit return logic for cancelled bookings**
- **Event-level cancellation functions**
- **Automated waitlist promotion**
- **Comprehensive testing for these workflows**

---

## 📋 **Proposed Database Changes**

### **Phase 1: Core Booking Cancellation** ⭐ HIGH PRIORITY

#### **1.1 New Function: `cancel_event_booking()`**

**Purpose**: Allow users/creators to cancel individual event bookings

**Parameters**:

```sql
cancel_event_booking(
  p_booking_id UUID,
  p_reason TEXT,
  p_minimum_hours_before INTEGER DEFAULT 24
) RETURNS JSONB
```

**Key Logic**:

- ✅ Permission checks (booking owner or event creator)
- ✅ Time-based cancellation policies
- ✅ Cash refund processing (set purchase.payment_status = 'refunded')
- ✅ Credit return processing (return credits to package)
- ✅ Booking status update (status = 'cancelled')
- ✅ Metadata storage (reason, timestamps, refund info)

**Dependencies**:

- ❓ Should we create helper functions for credit returns?
- ❓ Do we need waitlist promotion integration immediately?

#### **1.2 Test Implementation**

- ✅ Basic cancellation flow tests
- ✅ Credit vs cash refund scenarios
- ✅ Time-based policy enforcement
- ✅ Permission validation
- ✅ Error handling for edge cases

---

### **Phase 2: Event-Level Management** ⭐ MEDIUM PRIORITY

#### **2.1 New Function: `cancel_event()`**

**Purpose**: Allow creators to cancel entire events

**Parameters**:

```sql
cancel_event(
  p_event_id UUID,
  p_reason TEXT,
  p_refund_policy TEXT DEFAULT 'full'
) RETURNS JSONB
```

**Key Logic**:

- Cancel all confirmed bookings
- Process bulk refunds based on policy
- Update event status (set post.status = 'archived')
- Clear waitlist entries
- Notification triggers

#### **2.2 New Function: `delete_event()`**

**Purpose**: Permanent event deletion (admin/empty events only)

**Constraints**:

- Only for events with no bookings OR all bookings cancelled
- Cascade delete dates, tickets, live rooms
- Preserve audit trail in metadata

---

### **Phase 3: Waitlist Automation** ⭐ MEDIUM PRIORITY

#### **3.1 New Function: `promote_next_waitlist_user()`**

**Purpose**: Automatically promote waitlist when spots become available

**Parameters**:

```sql
promote_next_waitlist_user(
  p_event_id UUID,
  p_date_id UUID,
  p_ticket_id UUID DEFAULT NULL
) RETURNS JSONB
```

#### **3.2 Enhanced Function: `claim_waitlist_spot()`**

**Purpose**: Allow users to claim promoted waitlist spots

---

## 🔍 **Risk Assessment**

### **Low Risk Changes**:

- ✅ Adding new functions (no existing data affected)
- ✅ Adding metadata fields to existing records
- ✅ Status updates using existing enum values

### **Medium Risk Changes**:

- ⚠️ Bulk refund processing (could affect many records)
- ⚠️ Automated waitlist promotion (complex business logic)

### **High Risk Changes**:

- ❌ Changing existing table schemas
- ❌ Modifying existing function signatures
- ❌ Changing foreign key constraints

---

## 📝 **Implementation Strategy**

### **Recommended Approach**:

1. **Start Small**: Implement `cancel_event_booking()` first
2. **Test Thoroughly**: Full test coverage before moving to next phase
3. **Incremental Rollout**: Add features one at a time
4. **Rollback Plan**: Keep existing functions unchanged

### **Questions for Review**:

1. **Should we start with Phase 1 only?**

   - Implement `cancel_event_booking()` + tests
   - Get this working before moving to event-level cancellation

2. **Credit return logic placement?**

   - Include in main function OR create separate helper?
   - How to handle expired packages?

3. **Waitlist integration timing?**

   - Include in Phase 1 OR separate phase?
   - Auto-promotion vs manual?

4. **Notification system integration?**

   - Include in database functions OR handle in application layer?

5. **Testing strategy?**
   - Test functions individually OR integrated flows?
   - Mock external dependencies (Stripe, email)?

---

## 💡 **Recommended Next Steps**

### **Option A: Conservative Approach** (Recommended)

1. ✅ Implement ONLY `cancel_event_booking()` function
2. ✅ Create comprehensive tests
3. ✅ Validate in production-like environment
4. ✅ Get feedback and iterate
5. ✅ Then move to Phase 2

### **Option B: Aggressive Approach**

1. ✅ Implement all Phase 1 functions at once
2. ✅ Bulk test implementation
3. ⚠️ Higher risk, faster progress

### **Option C: Research First**

1. ✅ Create more detailed technical specs
2. ✅ Prototype critical logic in isolation
3. ✅ Then implement with confidence

---

## 🎯 **Specific Questions for Decision**

1. **Which approach do you prefer?** (A, B, or C)

2. **Should we prioritize credit returns or cash refunds first?**

3. **How important is waitlist automation vs manual processing?**

4. **Do you want to review the actual SQL before I implement it?**

5. **Should we test each function as we build it, or implement all then test?**

6. **Any specific business rules for refund policies that I should know?**

This plan ensures we make thoughtful, incremental changes while maintaining system stability. What's your preference for how we proceed?


