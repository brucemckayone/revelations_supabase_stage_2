# Backend Interface Guide

## Overview

This document provides a comprehensive guide to the backend systems and interfaces available for frontend integration. The backend is built on Supabase (PostgreSQL) with custom functions, triggers, and real-time subscriptions.

## Table of Contents

1. [Authentication & Profiles](#authentication--profiles)
2. [Services & Events](#services--events)
3. [Appointment System](#appointment-system)
4. [Waitlist System](#waitlist-system)
5. [Service Packages](#service-packages)
6. [Payment & Stripe Integration](#payment--stripe-integration)
7. [Notification System](#notification-system)
8. [Chat System](#chat-system)
9. [Real-time Subscriptions](#real-time-subscriptions)
10. [Error Handling](#error-handling)
11. [Data Types & Schemas](#data-types--schemas)

## Authentication & Profiles

### Auth Functions

```typescript
// Supabase Auth (built-in)
const { data, error } = await supabase.auth.signUp({
  email: "user@example.com",
  password: "password",
});

const { data, error } = await supabase.auth.signInWithPassword({
  email: "user@example.com",
  password: "password",
});

const { error } = await supabase.auth.signOut();
```

### Profile Management

```typescript
// Get user profile
const { data: profile } = await supabase
  .from("profiles")
  .select("*")
  .eq("id", userId)
  .single();

// Update profile
const { data, error } = await supabase
  .from("profiles")
  .update({
    full_name: "John Doe",
    avatar_url: "https://...",
    bio: "Professional description",
  })
  .eq("id", userId);
```

### Profile Schema

```typescript
interface Profile {
  id: string; // UUID, matches auth.users.id
  email: string;
  full_name?: string;
  avatar_url?: string;
  bio?: string;
  phone?: string;
  location?: string;
  website?: string;
  social_links?: Record<string, string>;
  onboarding_completed: boolean;
  created_at: string;
  updated_at: string;
}
```

## Services & Events

### Service Management

```typescript
// Get services (with filters)
const { data: services } = await supabase
  .from("services")
  .select(
    `
    *,
    post:posts(*),
    provider:profiles!posts.user_id(*)
  `
  )
  .eq("is_active", true)
  .order("created_at", { ascending: false });

// Get single service with full details
const { data: service } = await supabase
  .from("services")
  .select(
    `
    *,
    post:posts(*),
    provider:profiles!posts.user_id(*),
    packages:service_packages(*)
  `
  )
  .eq("id", serviceId)
  .single();
```

### Service Content Creation & Updates

```typescript
// Create service with full details including capacity and waitlist
const { data: serviceResult, error } = await supabase.rpc(
  "create_service_content_with_details",
  {
    p_title: "Wellness Coaching Session",
    p_slug: "wellness-coaching-session",
    p_description: "Personalized wellness coaching",
    p_content: "Detailed description of the service...",
    p_thumbnail_url: "https://...",
    p_tags: ["wellness", "coaching", "health"],
    p_status: "published",
    p_location_id: locationId,
    p_price: 75.0,
    p_duration: "01:30:00", // 1.5 hours
    p_type: "workshop",
    p_booking_workflow: "waitlist", // 'direct', 'pre-approval', 'waitlist', 'package'
    p_auto_confirm: false,
    p_confirmation_deadline_hours: 24,
    p_capacity: 5, // Maximum concurrent bookings
    p_waitlist_enabled: true,
  }
);

// Update service with new fields
const { data: updateResult, error } = await supabase.rpc(
  "update_service_content_with_details",
  {
    p_post_id: postId,
    p_title: "Updated Service Title",
    p_slug: "updated-service-slug",
    p_description: "Updated description",
    p_content: "Updated content...",
    p_thumbnail_url: "https://...",
    p_tags: ["updated", "tags"],
    p_status: "published",
    p_location_id: locationId,
    p_price: 85.0,
    p_duration: "01:45:00",
    p_type: "workshop",
    p_booking_workflow: "waitlist",
    p_auto_confirm: null, // Keep existing value
    p_confirmation_deadline_hours: null, // Keep existing value
    p_capacity: 8, // Update capacity
    p_waitlist_enabled: true,
  }
);
```

### Automatic Booking Workflow Switching

The system automatically switches between booking workflows based on capacity:

```typescript
// Get comprehensive workflow status
const { data: workflowStatus, error } = await supabase.rpc(
  "get_service_workflow_status",
  {
    p_service_id: serviceId,
  }
);

// Returns:
// {
//   service_id: "uuid",
//   title: "Service Name",
//   current_workflow: "waitlist", // Current active workflow
//   original_workflow: "direct", // Intended workflow set by provider
//   capacity: 5,
//   current_bookings: 5,
//   available_spots: 0,
//   waitlist_enabled: true,
//   is_auto_switched: true, // True if automatically switched to waitlist
//   can_book_directly: false, // Whether direct booking is available
//   requires_waitlist: true // Whether user must join waitlist
// }

// Manually change the original workflow (provider only)
const { error } = await supabase.rpc("set_service_original_workflow", {
  p_service_id: serviceId,
  p_original_workflow: "pre-approval", // When capacity opens, switch to this
});
```

#### Workflow Switching Logic

1. **At Capacity**: When `current_bookings >= capacity` and `waitlist_enabled = true`

   - Automatically switches `booking_workflow` to `'waitlist'`
   - Preserves original workflow in `original_booking_workflow`

2. **Below Capacity**: When `current_bookings < capacity`

   - Automatically switches back to `original_booking_workflow`
   - Only if currently on waitlist and original wasn't waitlist

3. **Real-time Updates**: Triggers fire on:
   - Appointment creation/cancellation/status changes
   - Direct service capacity/workflow updates
   - Manual capacity counter updates

```typescript
// Get comprehensive workflow status
const { data: workflowStatus, error } = await supabase.rpc(
  "get_service_workflow_status",
  {
    p_service_id: serviceId,
  }
);

// Returns:
// {
//   service_id: "uuid",
//   title: "Service Name",
//   current_workflow: "waitlist", // Current active workflow
//   original_workflow: "direct", // Intended workflow set by provider
//   capacity: 5,
//   current_bookings: 5,
//   available_spots: 0,
//   waitlist_enabled: true,
//   is_auto_switched: true, // True if automatically switched to waitlist
//   can_book_directly: false, // Whether direct booking is available
//   requires_waitlist: true // Whether user must join waitlist
// }

// Manually change the original workflow (provider only)
const { error } = await supabase.rpc("set_service_original_workflow", {
  p_service_id: serviceId,
  p_original_workflow: "pre-approval", // When capacity opens, switch to this
});
```

### Event Management

```typescript
// Get events with dates
const { data: events } = await supabase
  .from("events")
  .select(
    `
    *,
    post:posts(*),
    provider:profiles!posts.user_id(*),
    dates:event_dates(*)
  `
  )
  .eq("is_active", true);

// Get event with availability
const { data: eventDates } = await supabase
  .from("event_dates")
  .select(
    `
    *,
    event:events(*),
    available_spots: (capacity - current_bookings)
  `
  )
  .eq("event_id", eventId)
  .gte("start_date", new Date().toISOString());
```

### Service Schema

```typescript
interface Service {
  id: string;
  post_id: string;
  price: number;
  duration: string; // PostgreSQL interval
  booking_workflow: "direct" | "pre-approval" | "waitlist" | "package";
  original_booking_workflow: "direct" | "pre-approval" | "waitlist" | "package";
  auto_confirm: boolean;
  location?: string;
  capacity?: number;
  current_bookings: number;
  waitlist_enabled: boolean;
  is_active: boolean;
  metadata?: Record<string, any>;
  created_at: string;
  updated_at: string;
}

interface ServiceContentCreationResult {
  post_id: string;
  service_id: string;
  slug: string;
}
```

### Event Schema

```typescript
interface Event {
  id: string;
  post_id: string;
  event_type: "workshop" | "seminar" | "course" | "retreat" | "other";
  price: number;
  is_online: boolean;
  location?: string;
  max_attendees?: number;
  registration_deadline?: string;
  is_active: boolean;
  metadata?: Record<string, any>;
  created_at: string;
  updated_at: string;
}

interface EventDate {
  id: string;
  event_id: string;
  start_date: string;
  end_date: string;
  capacity?: number;
  current_bookings: number;
  waitlist_enabled: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}
```

## Appointment System

### Creating Appointments

```typescript
// Create appointment request
const { data: appointment, error } = await supabase.rpc(
  "create_appointment_request",
  {
    service_id: "service-uuid",
    appointment_date: "2025-01-15T10:00:00Z",
    duration: null, // Uses service duration if null
    notes: "Special requirements",
    package_purchase_id: null, // Optional: use package session
  }
);
```

### Appointment Management

```typescript
// Get user appointments
const { data: appointments } = await supabase
  .from("appointments")
  .select(
    `
    *,
    service:services(*),
    service_post:services.posts(*),
    provider:services.posts.profiles(*),
    package_purchase:service_package_purchases(*)
  `
  )
  .eq("user_id", userId)
  .order("appointment_date", { ascending: true });

// Update appointment status (provider only)
const { data, error } = await supabase.rpc("update_appointment_status", {
  appointment_id: "appointment-uuid",
  new_status: "confirmed",
  notes: "Confirmed for tomorrow",
});
```

### Cancel Appointment

```typescript
// Cancel appointment
const { data, error } = await supabase.rpc("cancel_appointment_request", {
  appointment_id: "appointment-uuid",
  cancellation_reason: "Schedule conflict",
  cancelled_by_provider: false,
});
```

### Appointment Schema

```typescript
interface Appointment {
  id: string;
  user_id: string;
  service_id: string;
  appointment_date: string;
  duration: string; // PostgreSQL interval
  status:
    | "pending_approval"
    | "pending_payment"
    | "pending_auto_payment"
    | "confirmed"
    | "cancelled"
    | "completed"
    | "no_show"
    | "rescheduled"
    | "pending_reschedule";
  booking_workflow: string;
  notes?: string;
  provider_notes?: string;
  cancellation_reason?: string;
  cancelled_by_provider: boolean;
  meeting_url?: string;
  package_purchase_id?: string;
  metadata?: Record<string, any>;
  created_at: string;
  updated_at: string;
}
```

## Waitlist System

### Joining Waitlists

```typescript
// Join service waitlist
const { data: waitlistEntry, error } = await supabase.rpc("join_waitlist", {
  user_id: userId,
  email: userEmail,
  service_id: "service-uuid",
});

// Join event waitlist
const { data: waitlistEntry, error } = await supabase.rpc("join_waitlist", {
  user_id: userId,
  email: userEmail,
  event_id: "event-uuid",
  event_date_id: "date-uuid",
});

// Join package waitlist
const { data: waitlistEntry, error } = await supabase.rpc("join_waitlist", {
  user_id: userId,
  email: userEmail,
  package_id: "package-uuid",
});
```

### Claiming Waitlist Spots

```typescript
// Claim waitlist spot (within 24-hour window)
const { data: claimResult, error } = await supabase.rpc("claim_waitlist_spot", {
  waitlist_entry_id: "entry-uuid",
});

// claimResult contains next action:
// {
//   type: 'service' | 'event' | 'package',
//   service_id?: string,
//   event_id?: string,
//   event_date_id?: string,
//   package_id?: string,
//   action: 'book_appointment' | 'book_event' | 'purchase_package'
// }
```

### Waitlist Management (Providers)

```typescript
// View waitlist for service
const { data: waitlist } = await supabase
  .from("waitlist_details_view")
  .select("*")
  .eq("service_info->>id", serviceId)
  .order("position");

// Manually notify waitlist
const { data: notificationCount, error } = await supabase.rpc(
  "notify_waitlist_manually",
  {
    service_id: serviceId,
    message: "Good news! We may have openings this week. Stay tuned!",
  }
);
```

### Waitlist Schema

```typescript
interface WaitlistEntry {
  id: string;
  user_id: string;
  email: string;
  service_id?: string;
  event_id?: string;
  event_date_id?: string;
  package_id?: string;
  position: number;
  status: "waiting" | "notified" | "claimed" | "expired" | "declined";
  last_notified_at?: string;
  notification_count: number;
  claim_expires_at?: string;
  metadata?: Record<string, any>;
  created_at: string;
  updated_at: string;
}
```

## Service Packages

### Package Management (Providers)

```typescript
// Create/update service package
const { data: package, error } = await supabase.rpc("manage_service_package", {
  service_id: "service-uuid",
  name: "4 Week Wellness Package",
  description: "Four comprehensive sessions over 4 weeks",
  sessions_count: 4,
  price: 299.99,
  duration_weeks: 6, // Valid for 6 weeks
  booking_window_days: 14,
  is_active: true,
  package_id: null, // null for new, UUID for update
});

// Get package usage stats
const { data: stats, error } = await supabase.rpc("get_package_usage_stats", {
  service_id: "service-uuid",
  package_id: "package-uuid", // optional, for specific package
});

// Create session template for recurring bookings
const { data: template, error } = await supabase.rpc(
  "create_package_session_template",
  {
    package_id: "package-uuid",
    name: "Weekly Wellness Sessions",
    frequency_type: "weekly", // 'weekly', 'biweekly', 'monthly', 'custom'
    frequency_interval: 1, // every 1 week
    preferred_days: [1, 3, 5], // Monday, Wednesday, Friday (0=Sunday)
    preferred_times: ["09:00", "14:00"], // 9 AM and 2 PM options
    description: "Regular weekly sessions for optimal progress",
    auto_schedule: false,
  }
);
```

### Package Purchasing (Users)

```typescript
// Purchase package
const { data: purchase, error } = await supabase.rpc(
  "purchase_service_package",
  {
    package_id: "package-uuid",
    amount: 299.99,
    stripe_payment_intent_id: "pi_...",
    currency: "usd",
  }
);

// Get user's active packages
const { data: packages, error } = await supabase.rpc(
  "get_user_service_packages",
  {
    service_id: "service-uuid",
  }
);

// Get comprehensive package dashboard
const { data: dashboard, error } = await supabase.rpc(
  "get_package_booking_dashboard",
  {
    package_purchase_id: "purchase-uuid",
  }
);

// Dashboard returns:
// {
//   package_purchase: { id, sessions_remaining, expires_at, created_at },
//   package: { id, name, description, sessions_count, duration_weeks },
//   service: { id, title, duration, booking_workflow },
//   upcoming_appointments: [...],
//   completed_appointments: [...],
//   available_templates: [...],
//   sessions_used: 2,
//   progress_percentage: 50.0
// }
```

### Multi-Date Package Booking

```typescript
// Get suggested session dates based on preferences
const { data: suggestions, error } = await supabase.rpc(
  "suggest_package_session_dates",
  {
    package_purchase_id: "purchase-uuid",
    sessions_count: 4, // How many sessions to suggest
    start_date: "2025-01-15", // When to start looking
    template_id: "template-uuid", // Optional: use specific template
  }
);

// Suggestions return:
// {
//   package_purchase_id: "uuid",
//   sessions_remaining: 4,
//   sessions_requested: 4,
//   suggested_dates: ["2025-01-15T09:00:00Z", "2025-01-22T09:00:00Z", ...],
//   scheduling_preferences: {
//     frequency_days: 7,
//     preferred_days: [1, 3, 5],
//     preferred_times: ["09:00", "14:00"]
//   },
//   template_used: "template-uuid",
//   provider_id: "provider-uuid"
// }

// Bulk book multiple sessions at once
const { data: bookingResult, error } = await supabase.rpc(
  "bulk_book_package_sessions",
  {
    package_purchase_id: "purchase-uuid",
    session_dates: [
      "2025-01-15T09:00:00Z",
      "2025-01-22T09:00:00Z",
      "2025-01-29T09:00:00Z",
      "2025-02-05T09:00:00Z",
    ],
    notes: "Bulk booking for wellness package",
  }
);

// Booking result:
// {
//   success: true,
//   package_purchase_id: "uuid",
//   sessions_booked: 4,
//   sessions_requested: 4,
//   appointment_ids: ["apt1", "apt2", "apt3", "apt4"],
//   failed_bookings: [], // Any failed bookings with error details
//   sessions_remaining: 0
// }
```

### Package Session Management

```typescript
// Book single appointment with package session
const { data: appointment, error } = await supabase.rpc(
  "create_appointment_request",
  {
    service_id: "service-uuid",
    appointment_date: "2025-01-15T10:00:00Z",
    package_purchase_id: "purchase-uuid", // Uses package session
  }
);

// Reschedule a package session
const { data: rescheduleResult, error } = await supabase.rpc(
  "reschedule_package_session",
  {
    appointment_id: "appointment-uuid",
    new_date: "2025-01-16T10:00:00Z",
    reason: "Schedule conflict resolved",
  }
);

// Get package sessions (appointments)
const { data: sessions } = await supabase
  .from("appointments")
  .select(
    `
    *,
    service:services(*),
    package_purchase:service_package_purchases(*)
  `
  )
  .eq("package_purchase_id", packagePurchaseId)
  .order("appointment_date", { ascending: true });
```

### Package Workflow Integration

```typescript
// Packages work with all booking workflows:

// 1. Direct booking workflow
// - Sessions are immediately confirmed when booked
// - Payment already handled during package purchase

// 2. Pre-approval workflow
// - Sessions require provider approval before confirmation
// - Provider can approve/reject individual sessions

// 3. Waitlist workflow
// - If service is at capacity, package holders can join waitlist
// - Package sessions are prioritized in waitlist processing

// Example: Check if package booking requires waitlist
const { data: workflowStatus } = await supabase.rpc(
  "get_service_workflow_status",
  { p_service_id: serviceId }
);

if (workflowStatus.requires_waitlist) {
  // Join waitlist for package
  const { data: waitlistEntry } = await supabase.rpc("join_waitlist", {
    user_id: userId,
    email: userEmail,
    package_id: packageId,
  });
} else {
  // Book directly with package
  const { data: appointment } = await supabase.rpc(
    "create_appointment_request",
    {
      service_id: serviceId,
      appointment_date: selectedDate,
      package_purchase_id: packagePurchaseId,
    }
  );
}
```

### Package Templates and Automation

```typescript
// Create different template types for various scheduling patterns

// Weekly template
const weeklyTemplate = await supabase.rpc("create_package_session_template", {
  package_id: packageId,
  name: "Weekly Therapy Sessions",
  frequency_type: "weekly",
  frequency_interval: 1,
  preferred_days: [2], // Tuesdays only
  preferred_times: ["10:00", "14:00"],
  description: "Consistent weekly sessions for therapy",
});

// Bi-weekly template
const biweeklyTemplate = await supabase.rpc("create_package_session_template", {
  package_id: packageId,
  name: "Bi-weekly Check-ins",
  frequency_type: "biweekly",
  frequency_interval: 1,
  preferred_days: [1, 3, 5], // Monday, Wednesday, Friday
  preferred_times: ["09:00"],
  description: "Every other week check-in sessions",
});

// Monthly intensive template
const monthlyTemplate = await supabase.rpc("create_package_session_template", {
  package_id: packageId,
  name: "Monthly Intensive Sessions",
  frequency_type: "monthly",
  frequency_interval: 1,
  preferred_days: [6], // Saturdays
  preferred_times: ["09:00"],
  description: "Monthly deep-dive sessions",
});

// Get available templates for a package
const { data: templates } = await supabase
  .from("package_session_templates")
  .select("*")
  .eq("package_id", packageId)
  .eq("is_active", true);
```

### Package Analytics and Tracking

```typescript
// Provider analytics for package performance
const { data: packageStats } = await supabase.rpc("get_package_usage_stats", {
  service_id: serviceId,
  package_id: packageId, // optional
});

// Returns:
// {
//   package_id: "uuid",
//   package_name: "4 Week Package",
//   total_purchases: 15,
//   total_sessions_sold: 60,
//   sessions_used: 45,
//   sessions_remaining: 15,
//   revenue: 4485.00,
//   active_customers: 8
// }

// Client package usage tracking
const { data: userPackages } = await supabase.rpc("get_user_service_packages", {
  service_id: serviceId,
});

// Track package session completion
const { data: completedSessions } = await supabase
  .from("appointments")
  .select("*")
  .eq("package_purchase_id", packagePurchaseId)
  .eq("status", "completed")
  .order("appointment_date", { ascending: false });
```

### Package Schemas

```typescript
interface ServicePackage {
  id: string;
  service_id: string;
  name: string;
  description?: string;
  sessions_count: number;
  price: number;
  duration_weeks?: number;
  booking_window_days: number;
  scheduling_preferences: {
    preferred_days?: number[]; // 0=Sunday, 1=Monday, etc.
    preferred_times?: string[]; // ["09:00", "14:00"]
    frequency_days?: number; // Default days between sessions
  };
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

interface ServicePackagePurchase {
  id: string;
  purchase_id: string;
  package_id: string;
  sessions_remaining: number;
  expires_at?: string;
  created_at: string;
  updated_at: string;
}

interface PackageSessionTemplate {
  id: string;
  package_id: string;
  name: string;
  description?: string;
  frequency_type: "weekly" | "biweekly" | "monthly" | "custom";
  frequency_interval: number;
  preferred_days: number[]; // 0=Sunday, 1=Monday, etc.
  preferred_times: string[]; // ["09:00", "14:00"]
  session_duration?: string; // PostgreSQL interval
  auto_schedule: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

interface PackageBookingDashboard {
  package_purchase: {
    id: string;
    sessions_remaining: number;
    expires_at?: string;
    created_at: string;
  };
  package: {
    id: string;
    name: string;
    description?: string;
    sessions_count: number;
    duration_weeks?: number;
    booking_window_days: number;
  };
  service: {
    id: string;
    title: string;
    duration: string;
    booking_workflow: string;
  };
  upcoming_appointments: Appointment[];
  completed_appointments: Appointment[];
  available_templates: PackageSessionTemplate[];
  sessions_used: number;
  progress_percentage: number;
}
```

## Payment & Stripe Integration

### Payment Processing

```typescript
// Create payment intent
const { data: paymentIntent, error } = await supabase.rpc(
  "create_payment_intent",
  {
    amount: 50.0,
    currency: "usd",
    service_id: "service-uuid",
    appointment_id: "appointment-uuid", // optional
    package_id: "package-uuid", // optional
  }
);

// Confirm payment
const { data: purchase, error } = await supabase.rpc("confirm_payment", {
  payment_intent_id: "pi_...",
  payment_method_id: "pm_...",
});
```

### Purchase Management

```typescript
// Get user purchases
const { data: purchases } = await supabase
  .from("purchases")
  .select(
    `
    *,
    service:services(*),
    appointment:appointments(*),
    package_purchase:service_package_purchases(*)
  `
  )
  .eq("user_id", userId)
  .order("purchase_date", { ascending: false });

// Get provider revenue
const { data: revenue } = await supabase
  .from("purchases")
  .select("amount, currency, purchase_date")
  .eq("owner_id", providerId)
  .eq("payment_status", "completed");
```

### Purchase Schema

```typescript
interface Purchase {
  id: string;
  user_id: string;
  owner_id: string;
  stripe_payment_intent_id?: string;
  amount: number;
  currency: string;
  payment_status:
    | "pending"
    | "completed"
    | "failed"
    | "cancelled"
    | "refunded"
    | "partially_refunded";
  purchase_type: "service" | "event" | "package";
  service_id?: string;
  event_id?: string;
  appointment_id?: string;
  purchase_date: string;
  start_date?: string;
  end_date?: string;
  refund_amount?: number;
  refund_reason?: string;
  metadata?: Record<string, any>;
  created_at: string;
  updated_at: string;
}
```

## Notification System

### Creating Notifications

```typescript
// Create notification (system or user-to-user)
const { data, error } = await supabase.rpc("create_notification", {
  recipient_id: "user-uuid",
  sender_id: null, // null for system notifications
  title: "Appointment Confirmed",
  message: "Your appointment has been confirmed for tomorrow at 10 AM",
  notification_type: "appointment",
  priority: 1, // 1=high, 2=medium, 3=low
  reference_id: "appointment-uuid",
  action_url: "/appointments/appointment-uuid",
  metadata: {
    appointment_id: "appointment-uuid",
    notification_subtype: "confirmed",
  },
});
```

### Managing Notifications

```typescript
// Get user notifications
const { data: notifications } = await supabase
  .from("notifications")
  .select(
    `
    *,
    sender:profiles!sender_id(full_name, avatar_url)
  `
  )
  .eq("recipient_id", userId)
  .order("created_at", { ascending: false })
  .limit(50);

// Mark as read
const { error } = await supabase
  .from("notifications")
  .update({ is_read: true, read_at: new Date().toISOString() })
  .eq("id", notificationId);

// Mark all as read
const { error } = await supabase
  .from("notifications")
  .update({ is_read: true, read_at: new Date().toISOString() })
  .eq("recipient_id", userId)
  .eq("is_read", false);
```

### Notification Schema

```typescript
interface Notification {
  id: string;
  recipient_id: string;
  sender_id?: string;
  title: string;
  message: string;
  notification_type:
    | "appointment"
    | "payment"
    | "message"
    | "waitlist"
    | "system";
  priority: 1 | 2 | 3; // high, medium, low
  is_read: boolean;
  read_at?: string;
  reference_id?: string;
  action_url?: string;
  metadata?: Record<string, any>;
  created_at: string;
  updated_at: string;
}
```

## Chat System

### Chat Management

```typescript
// Get or create chat
const { data: chat, error } = await supabase.rpc("get_or_create_chat", {
  participant_ids: [userId, providerId],
  chat_type: "appointment",
  reference_id: "appointment-uuid",
});

// Send message
const { data: message, error } = await supabase.rpc("send_chat_message", {
  chat_id: "chat-uuid",
  message_content: "Hello, I have a question about my appointment",
  message_type: "text",
});

// Get chat messages
const { data: messages } = await supabase
  .from("chat_messages")
  .select(
    `
    *,
    sender:profiles!sender_id(full_name, avatar_url)
  `
  )
  .eq("chat_id", chatId)
  .order("created_at", { ascending: true });
```

### Chat Schemas

```typescript
interface Chat {
  id: string;
  chat_type: "direct" | "appointment" | "group";
  reference_id?: string;
  metadata?: Record<string, any>;
  created_at: string;
  updated_at: string;
}

interface ChatMessage {
  id: string;
  chat_id: string;
  sender_id: string;
  message_content: string;
  message_type: "text" | "image" | "file" | "system";
  is_read: boolean;
  metadata?: Record<string, any>;
  created_at: string;
  updated_at: string;
}

interface ChatParticipant {
  id: string;
  chat_id: string;
  user_id: string;
  role: "member" | "admin";
  joined_at: string;
  last_read_at?: string;
}
```

## Real-time Subscriptions

### Setting up Subscriptions

```typescript
// Subscribe to notifications
const notificationSubscription = supabase
  .channel("notifications")
  .on(
    "postgres_changes",
    {
      event: "INSERT",
      schema: "public",
      table: "notifications",
      filter: `recipient_id=eq.${userId}`,
    },
    (payload) => {
      console.log("New notification:", payload.new);
      // Update UI with new notification
    }
  )
  .subscribe();

// Subscribe to chat messages
const chatSubscription = supabase
  .channel(`chat:${chatId}`)
  .on(
    "postgres_changes",
    {
      event: "INSERT",
      schema: "public",
      table: "chat_messages",
      filter: `chat_id=eq.${chatId}`,
    },
    (payload) => {
      console.log("New message:", payload.new);
      // Update chat UI
    }
  )
  .subscribe();

// Subscribe to appointment updates
const appointmentSubscription = supabase
  .channel("appointments")
  .on(
    "postgres_changes",
    {
      event: "UPDATE",
      schema: "public",
      table: "appointments",
      filter: `user_id=eq.${userId}`,
    },
    (payload) => {
      console.log("Appointment updated:", payload.new);
      // Update appointment status in UI
    }
  )
  .subscribe();
```

### Cleanup Subscriptions

```typescript
// Always cleanup subscriptions
useEffect(() => {
  return () => {
    notificationSubscription.unsubscribe();
    chatSubscription.unsubscribe();
    appointmentSubscription.unsubscribe();
  };
}, []);
```

## Error Handling

### Standard Error Patterns

```typescript
// Function call with error handling
const { data, error } = await supabase.rpc("some_function", params);

if (error) {
  // Handle specific error types
  if (error.code === "23505") {
    // Unique constraint violation
    toast.error("This item already exists");
  } else if (error.code === "42703") {
    // Column does not exist
    console.error("Database schema issue:", error.message);
  } else if (error.message?.includes("Access denied")) {
    // Custom function error
    toast.error("You don't have permission to perform this action");
  } else {
    // Generic error
    toast.error("An unexpected error occurred");
  }
  return;
}

// Use data safely
console.log("Success:", data);
```

### Common Error Codes

- `23505`: Unique constraint violation
- `23503`: Foreign key constraint violation
- `42703`: Column does not exist
- `42P01`: Table does not exist
- Custom function errors include descriptive messages

## Data Types & Schemas

### Common Enums

```typescript
// Appointment statuses
type AppointmentStatus =
  | "pending_approval"
  | "pending_payment"
  | "pending_auto_payment"
  | "confirmed"
  | "cancelled"
  | "completed"
  | "no_show"
  | "rescheduled"
  | "pending_reschedule";

// Booking workflows
type BookingWorkflow = "direct" | "pre-approval" | "waitlist" | "package";

// Payment statuses
type PaymentStatus =
  | "pending"
  | "completed"
  | "failed"
  | "cancelled"
  | "refunded"
  | "partially_refunded";

// Notification types
type NotificationType =
  | "appointment"
  | "payment"
  | "message"
  | "waitlist"
  | "system";

// Waitlist statuses
type WaitlistStatus =
  | "waiting"
  | "notified"
  | "claimed"
  | "expired"
  | "declined";
```

### Utility Types

```typescript
// Supabase response type
type SupabaseResponse<T> = {
  data: T | null;
  error: any | null;
};

// Database timestamp
type DbTimestamp = string; // ISO 8601 format

// PostgreSQL interval (for durations)
type DbInterval = string; // e.g., "01:30:00" for 1.5 hours

// Currency amount (stored as numeric in DB)
type CurrencyAmount = number;
```

### Integration Patterns

#### Loading States

```typescript
const [loading, setLoading] = useState(false);
const [error, setError] = useState<string | null>(null);

const handleAsyncOperation = async () => {
  setLoading(true);
  setError(null);

  try {
    const { data, error } = await supabase.rpc("some_function", params);

    if (error) throw error;

    // Handle success
    setData(data);
  } catch (err) {
    setError(err.message || "An error occurred");
  } finally {
    setLoading(false);
  }
};
```

#### Optimistic Updates

```typescript
const [appointments, setAppointments] = useState<Appointment[]>([]);

const cancelAppointment = async (appointmentId: string) => {
  // Optimistic update
  setAppointments((prev) =>
    prev.map((apt) =>
      apt.id === appointmentId ? { ...apt, status: "cancelled" } : apt
    )
  );

  try {
    const { error } = await supabase.rpc("cancel_appointment_request", {
      appointment_id: appointmentId,
      cancellation_reason: "User cancelled",
    });

    if (error) throw error;
  } catch (err) {
    // Revert optimistic update on error
    setAppointments((prev) =>
      prev.map((apt) =>
        apt.id === appointmentId
          ? { ...apt, status: "confirmed" } // revert to previous status
          : apt
      )
    );
    toast.error("Failed to cancel appointment");
  }
};
```

This guide provides comprehensive coverage of all backend systems and interfaces. Each section includes practical examples, complete schemas, and integration patterns that frontend developers can use to build robust applications on top of this backend infrastructure.
