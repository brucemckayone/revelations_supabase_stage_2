# Waitlist and Service Packages System

## Overview

The waitlist and service packages system provides comprehensive capacity management and multi-session pricing for both services and events. This system enables:

1. **First-come, first-serve waitlists** with hourly notifications
2. **Service packages** (2 weeks, 4 weeks, 10 weeks, etc.) with custom pricing
3. **Automatic capacity management** with real-time updates
4. **Claim windows** for waitlist notifications (24 hours by default)
5. **Manual provider notifications** to waitlist participants

## Key Features

### Waitlist System

- **Unified waitlists** for services, events, and service packages
- **Position-based queue** with automatic reordering
- **Hourly notifications** to next person in line when spots open
- **24-hour claim windows** with automatic expiry
- **Real-time capacity tracking** with automatic triggers

### Service Packages

- **Multi-session pricing** with custom duration and pricing
- **Session tracking** with automatic deduction on booking
- **Expiration management** with configurable duration
- **Package-specific waitlists** for sold-out packages
- **Usage analytics** for providers

## Database Schema

### Core Tables

#### `service_packages`

```sql
CREATE TABLE service_packages (
    id UUID PRIMARY KEY,
    service_id UUID NOT NULL REFERENCES services(id),
    name TEXT NOT NULL,                -- e.g., "2 Week Package"
    description TEXT,
    sessions_count INTEGER NOT NULL,   -- number of sessions included
    price NUMERIC(10,2) NOT NULL,
    duration_weeks INTEGER,            -- how long package is valid
    booking_window_days INTEGER DEFAULT 7,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### `waitlist_entries`

```sql
CREATE TABLE waitlist_entries (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    email VARCHAR(255) NOT NULL,

    -- References (exactly one must be non-null)
    service_id UUID REFERENCES services(id),
    event_id UUID REFERENCES events(id),
    event_date_id UUID REFERENCES event_dates(id),
    package_id UUID REFERENCES service_packages(id),

    -- Queue management
    position INTEGER NOT NULL,
    status TEXT DEFAULT 'waiting' CHECK (status IN ('waiting', 'notified', 'claimed', 'expired', 'declined')),

    -- Notification tracking
    last_notified_at TIMESTAMP WITH TIME ZONE,
    notification_count INTEGER DEFAULT 0,
    claim_expires_at TIMESTAMP WITH TIME ZONE,

    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### `service_package_purchases`

```sql
CREATE TABLE service_package_purchases (
    id UUID PRIMARY KEY,
    purchase_id UUID NOT NULL REFERENCES purchases(id),
    package_id UUID NOT NULL REFERENCES service_packages(id),
    sessions_remaining INTEGER NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Enhanced Tables

#### Services (enhanced with capacity)

- `capacity INTEGER` - Maximum concurrent bookings
- `current_bookings INTEGER` - Current active bookings
- `waitlist_enabled BOOLEAN` - Whether waitlist is enabled

#### Event Dates (enhanced with capacity)

- `capacity INTEGER` - Maximum attendees for this date
- `current_bookings INTEGER` - Current registrations
- `waitlist_enabled BOOLEAN` - Whether waitlist is enabled

#### Appointments (enhanced with packages)

- `package_purchase_id UUID` - Reference to package session used

## Core Functions

### Waitlist Management

#### `join_waitlist()`

```sql
SELECT public.join_waitlist(
    user_id,
    email,
    service_id := NULL,
    event_id := NULL,
    event_date_id := NULL,
    package_id := NULL
);
```

Join a waitlist for a service, event, or package. User gets assigned the next position in queue.

#### `claim_waitlist_spot()`

```sql
SELECT public.claim_waitlist_spot(
    waitlist_entry_id,
    user_id := NULL
);
```

Claim a waitlist spot within the claim window. Returns booking information for the next step.

#### `check_capacity_and_notify_waitlist()`

```sql
SELECT public.check_capacity_and_notify_waitlist();
```

Check for available capacity and notify the next person in each waitlist. Called automatically every hour.

### Service Package Management

#### `manage_service_package()`

```sql
SELECT public.manage_service_package(
    package_id := NULL,        -- NULL for new package
    service_id,
    name,
    description := NULL,
    sessions_count,
    price,
    duration_weeks := NULL,
    booking_window_days := 7,
    is_active := TRUE
);
```

Create or update service packages. Only service owners can manage their packages.

#### `purchase_service_package()`

```sql
SELECT public.purchase_service_package(
    package_id,
    user_id := NULL,
    stripe_payment_intent_id := NULL,
    amount,
    currency := 'usd'
);
```

Purchase a service package. Creates purchase record and tracks remaining sessions.

#### `get_user_service_packages()`

```sql
SELECT * FROM public.get_user_service_packages(
    service_id,
    user_id := NULL
);
```

Get user's active packages for a service with remaining sessions and expiration info.

### Appointment Booking with Packages

#### `create_appointment_request()`

```sql
SELECT public.create_appointment_request(
    service_id,
    appointment_date,
    duration := NULL,
    notes := NULL,
    package_purchase_id := NULL  -- Use package session
);
```

Create appointment request, optionally using a package session. Automatically deducts session if confirmed.

## Automated Processing

### Hourly Processor

The system runs `hourly_waitlist_processor()` every hour to:

1. **Update capacity counters** from current bookings
2. **Process expired claims** and reorder positions
3. **Check available spots** and notify next in line

### Real-time Triggers

- **Appointment changes** automatically update service capacity
- **Event booking changes** automatically update event capacity
- **Capacity changes** trigger waitlist notifications

### Notification Flow

1. **Spot opens** → System detects available capacity
2. **Next in line notified** → User gets high-priority notification
3. **24-hour claim window** → User has time to claim spot
4. **Auto-expire** → If not claimed, moves to next person
5. **Reorder queue** → Positions automatically updated

## Usage Examples

### Provider: Create Service Package

```javascript
// Create a 4-week package
const package = await supabase.rpc("manage_service_package", {
  service_id: "service-uuid",
  name: "4 Week Wellness Package",
  description: "Four 60-minute sessions over 4 weeks",
  sessions_count: 4,
  price: 320.0,
  duration_weeks: 6, // Valid for 6 weeks to allow scheduling flexibility
  booking_window_days: 14, // Can book up to 2 weeks in advance
});
```

### Provider: Enable Waitlist for Service

```javascript
// Enable waitlist with capacity limit
await supabase
  .from("services")
  .update({
    capacity: 5, // Max 5 concurrent bookings
    waitlist_enabled: true,
    booking_workflow: "waitlist",
  })
  .eq("id", serviceId);
```

### User: Join Waitlist

```javascript
const waitlistEntry = await supabase.rpc("join_waitlist", {
  user_id: userId,
  email: userEmail,
  service_id: serviceId,
});
```

### User: Purchase Package

```javascript
const purchase = await supabase.rpc("purchase_service_package", {
  package_id: packageId,
  amount: 320.0,
  stripe_payment_intent_id: paymentIntentId,
});
```

### User: Book with Package Session

```javascript
const appointment = await supabase.rpc("create_appointment_request", {
  service_id: serviceId,
  appointment_date: "2025-01-15T10:00:00Z",
  package_purchase_id: packagePurchaseId,
});
```

### User: Claim Waitlist Spot

```javascript
const claimResult = await supabase.rpc("claim_waitlist_spot", {
  waitlist_entry_id: entryId,
});

// claimResult contains next action:
// { type: 'service', service_id: '...', action: 'book_appointment' }
```

## Provider Analytics

### Package Usage Stats

```javascript
const stats = await supabase.rpc("get_package_usage_stats", {
  service_id: serviceId,
});

// Returns:
// {
//   package_name: "4 Week Package",
//   total_purchases: 15,
//   total_sessions_sold: 60,
//   sessions_used: 23,
//   sessions_remaining: 37,
//   revenue: 4800.00,
//   active_customers: 12
// }
```

### Waitlist Management

```javascript
// View waitlist for service
const waitlist = await supabase
  .from("waitlist_details_view")
  .select("*")
  .eq("service_info->>id", serviceId)
  .order("position");

// Manually notify waitlist
const notificationCount = await supabase.rpc("notify_waitlist_manually", {
  service_id: serviceId,
  message: "Good news! We may have openings this week. Stay tuned!",
});
```

## Integration with Existing Systems

### Appointment System

- Packages integrate seamlessly with existing appointment booking
- Session tracking happens automatically on confirmation
- Refunds handle partial package usage appropriately

### Payment System

- Packages create standard purchase records
- Stripe integration supports package payments
- Refund logic accounts for used vs unused sessions

### Notification System

- Waitlist notifications use existing notification infrastructure
- Providers receive updates on waitlist activity
- Users get timely notifications with action buttons

## Configuration Options

### Claim Window Duration

```sql
-- Modify in check_capacity_and_notify_waitlist()
v_claim_window_hours integer := 24; -- Default 24 hours
```

### Booking Workflows

- `direct` - Immediate booking (with/without payment)
- `pre-approval` - Requires provider approval
- `waitlist` - Automatic waitlist when at capacity
- `package` - Package-based booking only

### Capacity Management

- Set `capacity` for maximum concurrent bookings
- Enable `waitlist_enabled` for automatic waitlist
- Current bookings tracked automatically

## Monitoring and Maintenance

### Scheduled Tasks

- Run `hourly_waitlist_processor()` via cron every hour
- Monitor notification delivery rates
- Track claim window conversion rates

### Key Metrics

- Waitlist conversion rates (notified → claimed)
- Package utilization rates (sessions used vs expired)
- Provider response times to manual notifications
- System capacity utilization

### Troubleshooting

- Check `waitlist_details_view` for comprehensive waitlist state
- Monitor `claim_expires_at` for stuck notifications
- Verify capacity counters match actual bookings
- Review package expiration patterns

This system provides a robust foundation for capacity management and multi-session pricing while maintaining compatibility with existing appointment and payment systems.
