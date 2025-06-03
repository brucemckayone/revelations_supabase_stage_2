# Complete Package Booking System

## Overview

The package booking system allows providers to sell multi-session packages (e.g., "4 Week Wellness Package", "10 Session Therapy Package") and enables clients to book multiple dates from their purchased packages. The system is fully integrated with the existing appointment, payment, waitlist, and notification systems.

## Key Features

### 🎯 **Multi-Session Packages**

- Providers can create packages with any number of sessions
- Flexible pricing independent of individual session costs
- Optional expiration dates (e.g., "valid for 6 weeks")
- Booking windows (e.g., "book sessions up to 14 days in advance")

### 📅 **Smart Scheduling**

- **Bulk Booking**: Book multiple sessions at once
- **Intelligent Suggestions**: AI-powered date suggestions based on preferences
- **Session Templates**: Pre-configured scheduling patterns (weekly, bi-weekly, monthly)
- **Flexible Rescheduling**: Easy session rescheduling with package tracking

### 🔄 **Workflow Integration**

- Works with all booking workflows (direct, pre-approval, waitlist)
- Automatic workflow switching based on capacity
- Package holders get priority in waitlist systems
- Seamless payment integration (payment handled at package purchase)

### 📊 **Analytics & Tracking**

- Real-time session usage tracking
- Provider revenue analytics
- Client progress monitoring
- Package performance metrics

## System Architecture

### Core Tables

```sql
-- Service packages definition
service_packages (
  id, service_id, name, description, sessions_count,
  price, duration_weeks, booking_window_days,
  scheduling_preferences, is_active
)

-- Package purchases by users
service_package_purchases (
  id, purchase_id, package_id, sessions_remaining,
  expires_at, created_at, updated_at
)

-- Session scheduling templates
package_session_templates (
  id, package_id, name, frequency_type, frequency_interval,
  preferred_days, preferred_times, auto_schedule, is_active
)

-- Enhanced appointments table
appointments (
  ..., package_purchase_id, ... -- Links appointment to package session
)
```

### Key Functions

1. **Package Management**

   - `manage_service_package()` - Create/update packages
   - `purchase_service_package()` - Buy packages with Stripe
   - `get_package_usage_stats()` - Provider analytics

2. **Multi-Date Booking**

   - `suggest_package_session_dates()` - AI-powered scheduling suggestions
   - `bulk_book_package_sessions()` - Book multiple sessions at once
   - `get_package_booking_dashboard()` - Comprehensive client dashboard

3. **Session Management**
   - `create_appointment_request()` - Enhanced for package sessions
   - `reschedule_package_session()` - Package-aware rescheduling
   - `create_package_session_template()` - Create scheduling templates

## Complete Workflows

### 1. Provider Creates Package

```typescript
// Step 1: Create the package
const { data: package } = await supabase.rpc("manage_service_package", {
  service_id: "wellness-service-uuid",
  name: "4 Week Transformation Package",
  description:
    "Four personalized sessions over 4 weeks for complete wellness transformation",
  sessions_count: 4,
  price: 399.99,
  duration_weeks: 6, // Package expires in 6 weeks
  booking_window_days: 14, // Can book sessions up to 2 weeks ahead
});

// Step 2: Create scheduling templates (optional)
const weeklyTemplate = await supabase.rpc("create_package_session_template", {
  package_id: package.id,
  name: "Weekly Transformation Sessions",
  frequency_type: "weekly",
  frequency_interval: 1,
  preferred_days: [1, 3, 5], // Monday, Wednesday, Friday
  preferred_times: ["09:00", "14:00", "16:00"],
  description: "Consistent weekly sessions for optimal progress",
});

// Step 3: Update service to include package workflow
await supabase.rpc("update_service_content_with_details", {
  p_post_id: servicePostId,
  p_booking_workflow: "package", // Enable package booking
  // ... other service details
});
```

### 2. Client Purchases Package

```typescript
// Step 1: Browse available packages
const { data: packages } = await supabase
  .from("service_packages")
  .select("*")
  .eq("service_id", serviceId)
  .eq("is_active", true);

// Step 2: Purchase package (with Stripe)
const { data: purchase } = await supabase.rpc("purchase_service_package", {
  package_id: selectedPackage.id,
  amount: selectedPackage.price,
  stripe_payment_intent_id: paymentIntent.id,
  currency: "usd",
});

// Result: { purchase_id, package_purchase_id, sessions_remaining, expires_at }
```

### 3. Client Books Multiple Sessions

```typescript
// Step 1: Get package dashboard
const { data: dashboard } = await supabase.rpc(
  "get_package_booking_dashboard",
  {
    package_purchase_id: purchase.package_purchase_id,
  }
);

// Step 2: Get scheduling suggestions
const { data: suggestions } = await supabase.rpc(
  "suggest_package_session_dates",
  {
    package_purchase_id: purchase.package_purchase_id,
    sessions_count: 4, // Book all remaining sessions
    start_date: "2025-01-15",
    template_id: weeklyTemplate.id, // Use the weekly template
  }
);

// Step 3: Review and modify suggested dates
const selectedDates = [
  "2025-01-15T09:00:00Z", // Week 1
  "2025-01-22T09:00:00Z", // Week 2
  "2025-01-29T14:00:00Z", // Week 3 (different time)
  "2025-02-05T09:00:00Z", // Week 4
];

// Step 4: Bulk book all sessions
const { data: bookingResult } = await supabase.rpc(
  "bulk_book_package_sessions",
  {
    package_purchase_id: purchase.package_purchase_id,
    session_dates: selectedDates,
    notes: "Looking forward to the transformation journey!",
  }
);

// Result: { success: true, sessions_booked: 4, appointment_ids: [...] }
```

### 4. Session Management & Rescheduling

```typescript
// View upcoming sessions
const { data: upcomingSessions } = await supabase
  .from("appointments")
  .select(
    `
    *,
    service:services(*),
    package_purchase:service_package_purchases(*)
  `
  )
  .eq("package_purchase_id", packagePurchaseId)
  .gte("appointment_date", new Date().toISOString())
  .order("appointment_date");

// Reschedule a session
const { data: reschedule } = await supabase.rpc("reschedule_package_session", {
  appointment_id: upcomingSessions[0].id,
  new_date: "2025-01-16T10:00:00Z",
  reason: "Schedule conflict resolved",
});

// Cancel a session (sessions remain in package)
const { data: cancellation } = await supabase.rpc(
  "cancel_appointment_request",
  {
    appointment_id: appointmentId,
    cancellation_reason: "Need to reschedule",
    cancelled_by_provider: false,
  }
);
// Note: Cancelled package sessions return to the package balance
```

## Advanced Features

### 1. Intelligent Scheduling Suggestions

The system analyzes multiple factors to suggest optimal session dates:

```typescript
// Factors considered:
// - Provider availability
// - Client's previous booking patterns
// - Package template preferences
// - Service capacity and conflicts
// - Optimal session spacing for package type

const suggestions = await supabase.rpc("suggest_package_session_dates", {
  package_purchase_id: packageId,
  sessions_count: 6,
  start_date: "2025-01-15",
  template_id: templateId,
});

// Returns optimized schedule:
// {
//   suggested_dates: [
//     "2025-01-15T09:00:00Z", // Week 1
//     "2025-01-22T09:00:00Z", // Week 2
//     "2025-01-29T09:00:00Z", // Week 3
//     "2025-02-05T09:00:00Z", // Week 4
//     "2025-02-12T09:00:00Z", // Week 5
//     "2025-02-19T09:00:00Z"  // Week 6
//   ],
//   scheduling_preferences: { frequency_days: 7, preferred_days: [1], preferred_times: ["09:00"] }
// }
```

### 2. Package Templates for Different Use Cases

```typescript
// Therapy Package - Weekly consistency
const therapyTemplate = {
  name: "Weekly Therapy Sessions",
  frequency_type: "weekly",
  frequency_interval: 1,
  preferred_days: [2], // Tuesdays only
  preferred_times: ["10:00", "14:00", "16:00"],
  description: "Consistent weekly therapy for best outcomes",
};

// Fitness Package - 3x per week
const fitnessTemplate = {
  name: "Tri-Weekly Fitness Sessions",
  frequency_type: "custom",
  frequency_interval: 2, // Every 2-3 days
  preferred_days: [1, 3, 5], // Monday, Wednesday, Friday
  preferred_times: ["07:00", "18:00"],
  description: "Regular fitness sessions with rest days",
};

// Intensive Package - Bi-weekly deep sessions
const intensiveTemplate = {
  name: "Bi-Weekly Intensive Sessions",
  frequency_type: "biweekly",
  frequency_interval: 1,
  preferred_days: [6], // Saturdays
  preferred_times: ["09:00"],
  description: "Intensive bi-weekly sessions for deep work",
};
```

### 3. Package Analytics Dashboard

```typescript
// Provider analytics
const { data: stats } = await supabase.rpc("get_package_usage_stats", {
  service_id: serviceId,
});

// Returns comprehensive metrics:
// {
//   package_id: "uuid",
//   package_name: "4 Week Package",
//   total_purchases: 25,        // Total packages sold
//   total_sessions_sold: 100,   // Total sessions across all packages
//   sessions_used: 75,          // Sessions that have been booked/completed
//   sessions_remaining: 25,     // Sessions still available to book
//   revenue: 9975.00,          // Total revenue from this package
//   active_customers: 12       // Customers with remaining sessions
// }

// Client progress tracking
const { data: dashboard } = await supabase.rpc(
  "get_package_booking_dashboard",
  {
    package_purchase_id: packageId,
  }
);

// Returns detailed progress:
// {
//   package_purchase: { sessions_remaining: 2, expires_at: "2025-03-01" },
//   upcoming_appointments: [...],
//   completed_appointments: [...],
//   sessions_used: 2,
//   progress_percentage: 50.0
// }
```

### 4. Waitlist Integration

```typescript
// If service is at capacity, package holders can join waitlist
const { data: workflowStatus } = await supabase.rpc(
  "get_service_workflow_status",
  {
    p_service_id: serviceId,
  }
);

if (workflowStatus.requires_waitlist) {
  // Join waitlist for package
  const { data: waitlistEntry } = await supabase.rpc("join_waitlist", {
    user_id: userId,
    email: userEmail,
    package_id: packageId, // Special package waitlist
  });

  // Package holders get priority notifications
  // When spots open, they can claim and book with their package
}
```

## Error Handling & Edge Cases

### 1. Package Expiration

```typescript
// System automatically checks expiration
try {
  const booking = await supabase.rpc("bulk_book_package_sessions", {
    package_purchase_id: packageId,
    session_dates: dates,
  });
} catch (error) {
  if (error.message.includes("Package has expired")) {
    // Handle expired package
    showExpirationDialog();
  }
}
```

### 2. Insufficient Sessions

```typescript
// System validates session count
try {
  const booking = await supabase.rpc("bulk_book_package_sessions", {
    package_purchase_id: packageId,
    session_dates: [date1, date2, date3, date4, date5], // 5 sessions
  });
} catch (error) {
  if (error.message.includes("Not enough sessions remaining")) {
    // Handle insufficient sessions
    const available = error.message.match(/Available: (\d+)/)[1];
    showInsufficientSessionsDialog(available);
  }
}
```

### 3. Partial Booking Failures

```typescript
// Bulk booking handles partial failures gracefully
const { data: result } = await supabase.rpc("bulk_book_package_sessions", {
  package_purchase_id: packageId,
  session_dates: dates,
});

// Result includes both successes and failures:
// {
//   success: true,
//   sessions_booked: 3,
//   sessions_requested: 4,
//   appointment_ids: ["apt1", "apt2", "apt3"],
//   failed_bookings: [
//     { date: "2025-01-29T09:00:00Z", error: "Time slot not available" }
//   ],
//   sessions_remaining: 1
// }

// Handle partial failures
if (result.failed_bookings.length > 0) {
  showPartialBookingDialog(result);
}
```

## Integration with Existing Systems

### 1. Appointment System

- Package sessions are regular appointments with `package_purchase_id`
- All existing appointment features work (chat, notifications, rescheduling)
- Session deduction happens automatically on confirmation

### 2. Payment System

- Payment handled at package purchase (not per session)
- Refunds calculated based on unused sessions
- Stripe integration for package purchases

### 3. Notification System

- Package purchase confirmations
- Session booking confirmations
- Expiration warnings
- Progress updates

### 4. Chat System

- Each package session gets its own appointment chat
- Package-level chat for general questions
- Provider can message all package clients

## Frontend Implementation Guide

### 1. Package Purchase Flow

```typescript
// Package selection component
const PackageSelector = ({ serviceId }) => {
  const [packages, setPackages] = useState([]);

  useEffect(() => {
    const fetchPackages = async () => {
      const { data } = await supabase
        .from("service_packages")
        .select("*")
        .eq("service_id", serviceId)
        .eq("is_active", true);
      setPackages(data);
    };
    fetchPackages();
  }, [serviceId]);

  const handlePurchase = async (packageId, price) => {
    // Create Stripe payment intent
    const paymentIntent = await createPaymentIntent(price);

    // Confirm payment
    const { error } = await stripe.confirmCardPayment(
      paymentIntent.client_secret
    );

    if (!error) {
      // Complete package purchase
      const { data } = await supabase.rpc("purchase_service_package", {
        package_id: packageId,
        amount: price,
        stripe_payment_intent_id: paymentIntent.id,
      });

      // Redirect to booking dashboard
      router.push(`/packages/${data.package_purchase_id}/book`);
    }
  };

  return (
    <div className="package-grid">
      {packages.map((pkg) => (
        <PackageCard
          key={pkg.id}
          package={pkg}
          onPurchase={() => handlePurchase(pkg.id, pkg.price)}
        />
      ))}
    </div>
  );
};
```

### 2. Multi-Date Booking Interface

```typescript
// Package booking dashboard
const PackageBookingDashboard = ({ packagePurchaseId }) => {
  const [dashboard, setDashboard] = useState(null);
  const [suggestions, setSuggestions] = useState(null);
  const [selectedDates, setSelectedDates] = useState([]);

  useEffect(() => {
    const fetchDashboard = async () => {
      const { data } = await supabase.rpc("get_package_booking_dashboard", {
        package_purchase_id: packagePurchaseId,
      });
      setDashboard(data);
    };
    fetchDashboard();
  }, [packagePurchaseId]);

  const getSuggestions = async (templateId = null) => {
    const { data } = await supabase.rpc("suggest_package_session_dates", {
      package_purchase_id: packagePurchaseId,
      sessions_count: dashboard.package_purchase.sessions_remaining,
      template_id: templateId,
    });
    setSuggestions(data);
    setSelectedDates(data.suggested_dates);
  };

  const bookSessions = async () => {
    const { data } = await supabase.rpc("bulk_book_package_sessions", {
      package_purchase_id: packagePurchaseId,
      session_dates: selectedDates,
    });

    if (data.success) {
      toast.success(`Booked ${data.sessions_booked} sessions!`);
      // Refresh dashboard
      fetchDashboard();
    }
  };

  return (
    <div className="package-dashboard">
      <PackageProgress dashboard={dashboard} />
      <TemplateSelector
        templates={dashboard.available_templates}
        onSelect={getSuggestions}
      />
      <DateSelector
        suggestions={suggestions}
        selectedDates={selectedDates}
        onChange={setSelectedDates}
      />
      <BookingActions onBook={bookSessions} />
      <SessionsList sessions={dashboard.upcoming_appointments} />
    </div>
  );
};
```

## Summary

The package booking system is **fully implemented** and provides:

✅ **Complete Multi-Session Packages** - Create, purchase, and manage packages
✅ **Intelligent Bulk Booking** - Book multiple sessions with AI suggestions  
✅ **Flexible Scheduling Templates** - Weekly, bi-weekly, monthly patterns
✅ **Seamless Integration** - Works with all existing systems
✅ **Comprehensive Analytics** - Track usage, revenue, and progress
✅ **Error Handling** - Graceful handling of edge cases
✅ **Real-time Updates** - Live session tracking and notifications

The system enables providers to offer sophisticated multi-session packages while giving clients a smooth experience for booking and managing their sessions. All backend functions are implemented and ready for frontend integration.
