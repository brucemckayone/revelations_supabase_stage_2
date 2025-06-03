# 📋 Complete Package Appointment System Guide

## 🏗️ Database Schema

### Core Tables

#### 1. `service_packages`

**Purpose**: Defines service packages (e.g., "4-Session Therapy Package")

```typescript
interface ServicePackage {
  id: string; // UUID, auto-generated
  service_id: string; // FK to services.id
  name: string; // "4-Session Package", "Weekly Coaching Program"
  description?: string; // Package details
  sessions_count: number; // Number of sessions included
  price: number; // Total package price (numeric(10,2))
  duration_weeks?: number; // Package validity period
  booking_window_days: number; // Default: 7 days
  is_active: boolean; // Default: true
  scheduling_preferences: object; // JSONB for scheduling rules
  created_at: Date;
  updated_at: Date;
}
```

#### 2. `service_package_purchases`

**Purpose**: Tracks when users buy packages

```typescript
interface ServicePackagePurchase {
  id: string; // UUID, auto-generated
  purchase_id: string; // FK to purchases.id
  package_id: string; // FK to service_packages.id
  sessions_remaining: number; // Decrements with each booking
  expires_at?: Date; // When package expires
  created_at: Date;
  updated_at: Date;
}
```

#### 3. `package_session_templates`

**Purpose**: Smart scheduling templates

```typescript
interface PackageSessionTemplate {
  id: string;
  package_id: string; // FK to service_packages.id
  name: string; // "Weekly Sessions", "Bi-weekly Check-ins"
  description?: string;
  frequency_type: "weekly" | "biweekly" | "monthly" | "custom";
  frequency_interval: number; // Default: 1
  preferred_days: number[]; // [0,1,2,3,4,5,6] (Sunday=0)
  preferred_times: string[]; // ['09:00', '14:00']
  session_duration?: string; // Interval
  auto_schedule: boolean; // Default: false
  is_active: boolean; // Default: true
}
```

#### 4. `appointment_purchases` (Extended)

**Purpose**: Individual appointments (now supports packages)

```typescript
interface AppointmentPurchase {
  id: string;
  purchase_id: string; // FK to purchases.id
  service_id: string;
  appointment_date: Date;
  duration: number; // Minutes
  method: "video" | "phone" | "in-person";
  service_type: "reading" | "healing" | "coaching" | "consultation";
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
  notes?: string;
  meeting_url?: string;
  meeting_id?: string;
  payment_link?: string;
  metadata?: object;
  provider_notes?: string;
  // Package-related fields
  package_purchase_id?: string; // NEW: FK to service_package_purchases.id
  // Payment fields
  payment_reference?: string;
  payment_method?: string;
  payment_failure_reason?: string;
  transaction_reference?: string;
}
```

#### 5. `purchases` (Supporting Packages)

**Purpose**: Main purchase records

```typescript
interface Purchase {
  id: string;
  user_id: string; // Buyer
  owner_id: string; // Creator/Provider
  stripe_payment_intent_id?: string;
  stripe_invoice_id?: string;
  stripe_subscription_id?: string;
  stripe_customer_id?: string;
  amount: number;
  currency: string; // Default: 'GBP'
  payment_status: "completed" | "pending" | "refunded" | "failed" | "canceled";
  purchase_type:
    | "content"
    | "event"
    | "appointment"
    | "subscription"
    | "article";
  // Note: Packages use 'appointment' type with service_id set
  service_id?: string; // For package purchases
  content_id?: string;
  event_id?: string;
  post_id?: string;
  purchase_date: Date;
  start_date?: Date;
  end_date?: Date;
  quantity: number; // Default: 1
  metadata?: object;
}
```

---

## 🔧 Core Functions (Creator Perspective)

### 1. Create/Manage Service Packages

```sql
SELECT * FROM public.manage_service_package(
  p_service_id := 'uuid-here',
  p_name := '4-Session Transformation Package',
  p_sessions_count := 4,
  p_price := 320.00,
  p_booking_window_days := 14,
  p_package_id := null, -- null for create, uuid for update
  p_description := 'Complete transformation over 4 sessions with 20% discount',
  p_duration_weeks := 8,
  p_is_active := true
);
```

**Frontend Integration:**

```typescript
// Create package
const createPackage = async (packageData: {
  service_id: string;
  name: string;
  sessions_count: number;
  price: number;
  booking_window_days?: number;
  description?: string;
  duration_weeks?: number;
}) => {
  const { data, error } = await supabase.rpc("manage_service_package", {
    p_service_id: packageData.service_id,
    p_name: packageData.name,
    p_sessions_count: packageData.sessions_count,
    p_price: packageData.price,
    p_booking_window_days: packageData.booking_window_days || 7,
    p_description: packageData.description,
    p_duration_weeks: packageData.duration_weeks,
    p_is_active: true,
  });

  return { data, error };
};
```

### 2. Create Scheduling Templates

```sql
SELECT * FROM public.create_package_session_template(
  p_package_id := 'package-uuid',
  p_name := 'Weekly Monday Sessions',
  p_frequency_type := 'weekly',
  p_frequency_interval := 1,
  p_preferred_days := ARRAY[1], -- Monday
  p_preferred_times := ARRAY['09:00'::time, '14:00'::time],
  p_description := 'Weekly sessions every Monday',
  p_auto_schedule := false
);
```

**Frontend Integration:**

```typescript
const createSessionTemplate = async (templateData: {
  package_id: string;
  name: string;
  frequency_type: "weekly" | "biweekly" | "monthly" | "custom";
  frequency_interval?: number;
  preferred_days?: number[];
  preferred_times?: string[];
  description?: string;
  auto_schedule?: boolean;
}) => {
  const { data, error } = await supabase.rpc(
    "create_package_session_template",
    templateData
  );
  return { data, error };
};
```

### 3. Get Creator's Packages

```sql
SELECT * FROM public.get_user_service_packages(
  p_user_id := auth.uid(), -- Creator ID
  p_service_id := 'service-uuid' -- Optional: filter by service
);
```

**Returns:**

```typescript
interface PackageWithStats {
  package_id: string;
  name: string;
  description: string;
  sessions_count: number;
  price: number;
  duration_weeks: number;
  booking_window_days: number;
  is_active: boolean;
  service_title: string;
  total_purchased: number;
  total_revenue: number;
  active_purchases: number;
  sessions_booked: number;
  sessions_completed: number;
  avg_utilization: number;
}
```

### 4. Get Package Usage Stats

```sql
SELECT * FROM public.get_package_usage_stats(
  p_package_id := 'package-uuid',
  p_period_months := 3 -- Last 3 months
);
```

---

## 💳 Stripe Integration Flow

### Package Purchase Flow

#### 1. **Frontend: Create Stripe Payment Intent**

```typescript
// 1. Get package details
const { data: package } = await supabase
  .from("service_packages")
  .select("*")
  .eq("id", packageId)
  .single();

// 2. Create Stripe Payment Intent
const paymentIntent = await stripe.paymentIntents.create({
  amount: Math.round(package.price * 100), // Convert to cents
  currency: "usd",
  metadata: {
    package_id: packageId,
    service_id: package.service_id,
    purchase_type: "package",
    sessions_count: package.sessions_count.toString(),
  },
});

// 3. Store payment intent ID for webhook processing
```

#### 2. **Frontend: Confirm Payment**

```typescript
const { error } = await stripe.confirmCardPayment(paymentIntent.client_secret, {
  payment_method: {
    card: cardElement,
    billing_details: {
      name: user.name,
      email: user.email,
    },
  },
});

if (!error) {
  // Payment successful - webhook will handle database updates
  router.push(`/packages/${packageId}/success`);
}
```

#### 3. **Backend: Stripe Webhook Handler**

```typescript
// webhook-handler.ts
export async function handlePaymentIntentSucceeded(
  paymentIntent: Stripe.PaymentIntent
) {
  const { package_id, service_id, sessions_count } = paymentIntent.metadata;

  if (!package_id) return; // Not a package purchase

  // Call the purchase function
  const { data, error } = await supabase.rpc("purchase_service_package", {
    p_package_id: package_id,
    p_amount: paymentIntent.amount / 100, // Convert back from cents
    p_stripe_payment_intent_id: paymentIntent.id,
    p_user_id: paymentIntent.metadata.user_id || null,
    p_currency: paymentIntent.currency,
  });

  if (error) {
    console.error("Failed to create package purchase:", error);
    // Handle error - possibly refund
  }

  return data;
}
```

#### 4. **Database: Purchase Processing**

The `purchase_service_package` function:

1. Creates a `purchases` record with `purchase_type = 'appointment'` and `service_id`
2. Creates a `service_package_purchases` record with full `sessions_remaining`
3. Sets expiration date based on `duration_weeks`

---

## 📅 Appointment Booking (Customer Perspective)

### 1. Get Available Packages for User

```sql
SELECT * FROM public.get_user_service_packages(
  p_user_id := 'customer-uuid',
  p_service_id := 'service-uuid'
);
```

### 2. Get Package Dashboard

```sql
SELECT * FROM public.get_package_booking_dashboard(
  p_package_purchase_id := 'package-purchase-uuid'
);
```

**Returns comprehensive data:**

```typescript
interface PackageDashboard {
  package_purchase: {
    id: string;
    sessions_remaining: number;
    expires_at: Date;
    created_at: Date;
  };
  package: {
    id: string;
    name: string;
    description: string;
    sessions_count: number;
    duration_weeks: number;
    booking_window_days: number;
  };
  service: {
    id: string;
    title: string;
    duration: string;
    booking_workflow: string;
  };
  upcoming_appointments: AppointmentSummary[];
  completed_appointments: AppointmentSummary[];
  available_templates: SessionTemplate[];
  sessions_used: number;
  progress_percentage: number;
}
```

### 3. Get Suggested Session Dates

```sql
SELECT * FROM public.suggest_package_session_dates(
  p_package_purchase_id := 'package-purchase-uuid',
  p_sessions_count := 4, -- How many to suggest
  p_start_date := '2024-01-15'::date,
  p_template_id := 'template-uuid' -- Optional
);
```

**Returns:**

```typescript
interface SuggestedDates {
  package_purchase_id: string;
  sessions_needed: number;
  sessions_remaining: number;
  suggested_dates: Date[];
  preferences: {
    preferred_days: number[];
    preferred_times: string[];
    frequency_days: number;
    start_date: Date;
    template_used?: string;
  };
}
```

### 4. Book Multiple Sessions

```sql
SELECT * FROM public.bulk_book_package_sessions(
  p_package_purchase_id := 'package-purchase-uuid',
  p_session_dates := ARRAY[
    '2024-01-15 09:00:00+00'::timestamptz,
    '2024-01-22 09:00:00+00'::timestamptz,
    '2024-01-29 09:00:00+00'::timestamptz,
    '2024-02-05 09:00:00+00'::timestamptz
  ],
  p_notes := 'Bulk booking for transformation package'
);
```

**Returns:**

```typescript
interface BulkBookingResult {
  success: boolean;
  package_purchase_id: string;
  sessions_booked: number;
  sessions_requested: number;
  appointment_ids: string[];
  failed_bookings: Array<{
    date: Date;
    error: string;
  }>;
  sessions_remaining: number;
}
```

### 5. Reschedule Session

```sql
SELECT * FROM public.reschedule_package_session(
  p_appointment_id := 'appointment-uuid',
  p_new_date := '2024-01-30 14:00:00+00'::timestamptz,
  p_reason := 'Client requested schedule change'
);
```

---

## 🎨 Frontend Components & Flows

### Creator Dashboard Components

#### 1. Package Management Component

```typescript
// components/PackageManager.tsx
const PackageManager = ({ serviceId }: { serviceId: string }) => {
  const [packages, setPackages] = useState<ServicePackage[]>([]);

  const loadPackages = async () => {
    const { data } = await supabase.rpc("get_user_service_packages", {
      p_user_id: user.id,
      p_service_id: serviceId,
    });
    setPackages(data);
  };

  const createPackage = async (packageData: CreatePackageData) => {
    const { data, error } = await supabase.rpc("manage_service_package", {
      p_service_id: serviceId,
      ...packageData,
    });

    if (!error) {
      loadPackages(); // Refresh list
    }
  };

  return (
    <div>
      <PackageList packages={packages} />
      <CreatePackageForm onSubmit={createPackage} />
    </div>
  );
};
```

#### 2. Package Analytics Component

```typescript
// components/PackageAnalytics.tsx
const PackageAnalytics = ({ packageId }: { packageId: string }) => {
  const [stats, setStats] = useState<PackageStats>();

  useEffect(() => {
    const loadStats = async () => {
      const { data } = await supabase.rpc("get_package_usage_stats", {
        p_package_id: packageId,
        p_period_months: 3,
      });
      setStats(data);
    };
    loadStats();
  }, [packageId]);

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
      <StatCard title="Total Sales" value={stats?.total_revenue} />
      <StatCard title="Active Packages" value={stats?.active_purchases} />
      <StatCard title="Completion Rate" value={`${stats?.avg_utilization}%`} />
    </div>
  );
};
```

### Customer Experience Components

#### 1. Package Selection Component

```typescript
// components/PackageSelector.tsx
const PackageSelector = ({ serviceId }: { serviceId: string }) => {
  const [packages, setPackages] = useState<ServicePackage[]>([]);

  const loadPackages = async () => {
    const { data } = await supabase
      .from("service_packages")
      .select("*")
      .eq("service_id", serviceId)
      .eq("is_active", true);
    setPackages(data);
  };

  const handlePurchase = async (packageId: string) => {
    // Create Stripe Payment Intent
    const response = await fetch("/api/create-payment-intent", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ packageId }),
    });

    const { client_secret } = await response.json();

    // Show Stripe checkout
    const { error } = await stripe.confirmCardPayment(client_secret, {
      payment_method: { card: cardElement },
    });

    if (!error) {
      router.push(`/packages/${packageId}/dashboard`);
    }
  };

  return (
    <div className="grid gap-4">
      {packages.map((pkg) => (
        <PackageCard
          key={pkg.id}
          package={pkg}
          onPurchase={() => handlePurchase(pkg.id)}
        />
      ))}
    </div>
  );
};
```

#### 2. Package Dashboard Component

```typescript
// components/PackageDashboard.tsx
const PackageDashboard = ({
  packagePurchaseId,
}: {
  packagePurchaseId: string;
}) => {
  const [dashboard, setDashboard] = useState<PackageDashboard>();

  const loadDashboard = async () => {
    const { data } = await supabase.rpc("get_package_booking_dashboard", {
      p_package_purchase_id: packagePurchaseId,
    });
    setDashboard(data);
  };

  const suggestDates = async () => {
    const { data } = await supabase.rpc("suggest_package_session_dates", {
      p_package_purchase_id: packagePurchaseId,
      p_sessions_count: dashboard.package_purchase.sessions_remaining,
    });
    return data;
  };

  const bulkBook = async (dates: Date[]) => {
    const { data } = await supabase.rpc("bulk_book_package_sessions", {
      p_package_purchase_id: packagePurchaseId,
      p_session_dates: dates.map((d) => d.toISOString()),
    });

    if (data.success) {
      loadDashboard(); // Refresh
    }
  };

  return (
    <div>
      <PackageProgress dashboard={dashboard} />
      <UpcomingAppointments appointments={dashboard.upcoming_appointments} />
      <BookingSuggestions onSuggest={suggestDates} onBook={bulkBook} />
      <CompletedSessions sessions={dashboard.completed_appointments} />
    </div>
  );
};
```

---

## 🔐 Security & Permissions

### Row Level Security (RLS) Policies

All package-related tables have RLS enabled with these patterns:

1. **Creators can manage their own packages**
2. **Customers can view packages for services they can access**
3. **Customers can only access their own purchases**
4. **Appointment bookings follow existing service permissions**

### Function Security

All functions use `SECURITY DEFINER` with proper user verification:

- `auth.uid()` checks for authenticated users
- Service ownership verification for creators
- Purchase ownership verification for customers

---

## 📊 Key Metrics & Analytics

### For Creators:

- Package sales volume and revenue
- Session utilization rates
- Popular package types
- Customer retention through packages
- Average time between sessions

### For Customers:

- Sessions remaining
- Package expiration dates
- Progress tracking
- Session history
- Booking suggestions

This system provides a comprehensive package-based appointment booking solution with intelligent scheduling, Stripe integration, and detailed analytics for both creators and customers.

# 📅 User Package Booking Experience

## 🎯 **TL;DR: Users have FULL flexibility to choose their own dates**

The system offers **three booking approaches**:

1. **🎯 Manual Date Selection** (Full Control)
2. **🤖 AI Suggestions** (Smart Recommendations)
3. **📋 Template-Based** (Preset Schedules)

---

## 🛒 **Step 1: After Purchasing a Package**

When a user buys a 4-session package, they get:

- **4 sessions remaining**
- **Expiration date** (e.g., 8 weeks from purchase)
- **Full booking flexibility** within those constraints

---

## 🗓️ **Step 2: Booking Options (User's Choice)**

### **Option A: Manual Date Selection**

**👤 "I want to pick my own dates"**

```typescript
// User selects their own specific dates
const selectedDates = [
  "2024-01-15T09:00:00Z", // Monday 9 AM
  "2024-01-25T14:00:00Z", // Thursday 2 PM
  "2024-02-03T10:30:00Z", // Saturday 10:30 AM
  "2024-02-15T16:00:00Z", // Thursday 4 PM
];

// Book all at once
const result = await supabase.rpc("bulk_book_package_sessions", {
  p_package_purchase_id: packageId,
  p_session_dates: selectedDates,
  p_notes: "My custom schedule",
});
```

**Or book one at a time:**

```typescript
// Book individual sessions as they go
const result = await supabase.rpc("create_appointment_request", {
  p_service_id: serviceId,
  p_appointment_date: "2024-01-15T09:00:00Z",
  p_notes: "First session",
  p_package_purchase_id: packageId,
});
```

### **Option B: Get AI Suggestions**

**🤖 "Help me find the best times"**

```typescript
// Get smart suggestions based on preferences
const suggestions = await supabase.rpc("suggest_package_session_dates", {
  p_package_purchase_id: packageId,
  p_sessions_count: 4, // How many to suggest
  p_start_date: "2024-01-15", // When to start
  p_template_id: null, // No template (use package prefs)
});

// Returns suggested dates the user can accept, modify, or reject
console.log(suggestions.suggested_dates);
// ["2024-01-15T09:00:00Z", "2024-01-22T09:00:00Z", "2024-01-29T09:00:00Z", "2024-02-05T09:00:00Z"]

// User can accept all, pick some, or modify
const acceptedDates = suggestions.suggested_dates.slice(0, 2); // Take first 2
const customDates = ["2024-02-10T14:00:00Z", "2024-02-20T11:00:00Z"]; // Add 2 custom

const finalDates = [...acceptedDates, ...customDates];
```

### **Option C: Use Templates**

**📋 "I want a preset schedule"**

If the provider created templates:

```typescript
// Get available templates
const dashboard = await supabase.rpc("get_package_booking_dashboard", {
  p_package_purchase_id: packageId,
});

const templates = dashboard.available_templates;
// [
//   { id: "template1", name: "Weekly Mondays", frequency_type: "weekly", preferred_days: [1], preferred_times: ["09:00"] },
//   { id: "template2", name: "Bi-weekly Fridays", frequency_type: "biweekly", preferred_days: [5], preferred_times: ["14:00"] }
// ]

// Use template to get suggestions
const templateSuggestions = await supabase.rpc(
  "suggest_package_session_dates",
  {
    p_package_purchase_id: packageId,
    p_sessions_count: 4,
    p_start_date: "2024-01-15",
    p_template_id: "template1", // Use "Weekly Mondays" template
  }
);
```

---

## 🎨 **Frontend UI Flow**

### **Package Dashboard Component**

```typescript
const PackageDashboard = ({ packagePurchaseId }) => {
  const [bookingMode, setBookingMode] = useState("manual"); // 'manual' | 'suggestions' | 'template'
  const [selectedDates, setSelectedDates] = useState([]);

  return (
    <div className="package-dashboard">
      {/* Progress Section */}
      <PackageProgress
        sessionsUsed={dashboard.sessions_used}
        sessionsTotal={dashboard.package.sessions_count}
        expiresAt={dashboard.package_purchase.expires_at}
      />

      {/* Booking Mode Selector */}
      <div className="booking-mode-tabs">
        <button
          onClick={() => setBookingMode("manual")}
          className={bookingMode === "manual" ? "active" : ""}
        >
          📅 Pick Your Dates
        </button>
        <button
          onClick={() => setBookingMode("suggestions")}
          className={bookingMode === "suggestions" ? "active" : ""}
        >
          🤖 Get Suggestions
        </button>
        <button
          onClick={() => setBookingMode("template")}
          className={bookingMode === "template" ? "active" : ""}
        >
          📋 Use Template
        </button>
      </div>

      {/* Booking Interface */}
      {bookingMode === "manual" && (
        <ManualDatePicker
          sessionsRemaining={dashboard.package_purchase.sessions_remaining}
          onDatesSelected={setSelectedDates}
          onBook={handleBulkBook}
        />
      )}

      {bookingMode === "suggestions" && (
        <SuggestionInterface
          packagePurchaseId={packagePurchaseId}
          onDatesSelected={setSelectedDates}
          onBook={handleBulkBook}
        />
      )}

      {bookingMode === "template" && (
        <TemplateInterface
          templates={dashboard.available_templates}
          packagePurchaseId={packagePurchaseId}
          onDatesSelected={setSelectedDates}
          onBook={handleBulkBook}
        />
      )}
    </div>
  );
};
```

### **Manual Date Picker**

```typescript
const ManualDatePicker = ({ sessionsRemaining, onDatesSelected, onBook }) => {
  const [selectedDates, setSelectedDates] = useState([]);

  const handleDateClick = (date) => {
    if (selectedDates.length < sessionsRemaining) {
      setSelectedDates([...selectedDates, date]);
    }
  };

  return (
    <div>
      <h3>Select {sessionsRemaining} appointment times</h3>

      {/* Calendar Component */}
      <Calendar
        onDateTimeSelect={handleDateClick}
        selectedDates={selectedDates}
        maxSelections={sessionsRemaining}
        availability={providerAvailability}
      />

      {/* Selected Dates Preview */}
      <div className="selected-dates">
        {selectedDates.map((date, i) => (
          <div key={i} className="date-chip">
            {format(date, "PPp")}
            <button onClick={() => removeDate(i)}>×</button>
          </div>
        ))}
      </div>

      {/* Book Button */}
      <button
        disabled={selectedDates.length === 0}
        onClick={() => onBook(selectedDates)}
        className="book-sessions-btn"
      >
        Book {selectedDates.length} Sessions
      </button>
    </div>
  );
};
```

### **AI Suggestions Interface**

```typescript
const SuggestionInterface = ({
  packagePurchaseId,
  onDatesSelected,
  onBook,
}) => {
  const [suggestions, setSuggestions] = useState([]);
  const [selectedFromSuggestions, setSelectedFromSuggestions] = useState([]);

  const getSuggestions = async () => {
    const { data } = await supabase.rpc("suggest_package_session_dates", {
      p_package_purchase_id: packagePurchaseId,
      p_sessions_count: sessionsRemaining,
    });
    setSuggestions(data.suggested_dates);
  };

  return (
    <div>
      <button onClick={getSuggestions} className="get-suggestions-btn">
        🤖 Get Smart Suggestions
      </button>

      {suggestions.length > 0 && (
        <div className="suggestions-list">
          <h4>Recommended Times:</h4>
          {suggestions.map((date, i) => (
            <div key={i} className="suggestion-item">
              <input
                type="checkbox"
                checked={selectedFromSuggestions.includes(date)}
                onChange={(e) => toggleSuggestion(date, e.target.checked)}
              />
              <span>{format(new Date(date), "PPp")}</span>
              <span className="suggestion-reason">Optimal spacing</span>
            </div>
          ))}

          <div className="suggestion-actions">
            <button onClick={() => setSelectedFromSuggestions(suggestions)}>
              ✓ Accept All
            </button>
            <button onClick={() => onBook(selectedFromSuggestions)}>
              Book Selected ({selectedFromSuggestions.length})
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
```

---

## 🔄 **Flexibility Features**

### **1. Mix and Match Approaches**

```typescript
// User can combine all approaches
const finalDates = [
  ...acceptedSuggestions, // 2 AI suggestions
  ...manuallyPickedDates, // 1 custom date
  ...templateBasedDate, // 1 from template
];

await bulkBook(finalDates);
```

### **2. Progressive Booking**

```typescript
// User doesn't have to book all sessions at once
// Book 2 now, 2 later
await bulkBook(selectedDates.slice(0, 2));

// Later... book remaining sessions
await bulkBook(selectedDates.slice(2, 4));
```

### **3. Rescheduling**

```typescript
// User can reschedule any session
await supabase.rpc("reschedule_package_session", {
  p_appointment_id: appointmentId,
  p_new_date: "2024-02-20T15:00:00Z",
  p_reason: "Schedule conflict",
});
```

---

## 🚦 **Constraints & Validations**

The system enforces these rules:

1. **✅ Sessions Remaining**: Can't book more than purchased
2. **⏰ Package Expiration**: Must book before expiration date
3. **📅 Booking Window**: Respects `booking_window_days` (e.g., can book 14 days ahead)
4. **🔄 Provider Availability**: Checks for conflicts with existing appointments
5. **⚡ Real-time Validation**: Each date is validated when booking

---

## 💭 **User Experience Summary**

**The user has complete control:**

- ✅ Pick any dates/times they want
- ✅ Use AI suggestions as starting point
- ✅ Follow provider templates if available
- ✅ Mix different approaches
- ✅ Book all at once or progressively
- ✅ Reschedule any session
- ✅ See clear progress tracking

**The system provides:**

- 🤖 Smart suggestions based on preferences
- 📋 Pre-made templates from providers
- 🔍 Real-time availability checking
- ⚠️ Clear constraint messaging
- 📊 Progress tracking and reminders

So to answer your question directly: **Users can absolutely choose specific dates!** The system offers helpful suggestions and templates, but the user always has the final say on when their sessions are scheduled.
