# Universal Packages System: Complete Frontend Implementation Guide

## Table of Contents

1. [System Overview & Migration from Legacy](#system-overview--migration-from-legacy)
2. [Database Schema Changes](#database-schema-changes)
3. [API Functions & Database Calls](#api-functions--database-calls)
4. [TypeScript Types & Interfaces](#typescript-types--interfaces)
5. [Stripe Integration Implementation](#stripe-integration-implementation)
6. [Frontend Component Architecture](#frontend-component-architecture)
7. [State Management with Jotai](#state-management-with-jotai)
8. [TanStack Query Integration](#tanstack-query-integration)
9. [User Experience Flows](#user-experience-flows)
10. [Package Creation & Management](#package-creation--management)
11. [Content Access Control](#content-access-control)
12. [Analytics & Dashboard Implementation](#analytics--dashboard-implementation)
13. [Testing Strategy](#testing-strategy)
14. [Performance Optimization](#performance-optimization)

## System Overview & Migration from Legacy

### What Changed from the Old System

#### **Legacy System** (Service Packages)

- **Scope**: Appointment packages only
- **Table**: `service_packages` (limited to one service)
- **Function**: `process_package_purchase_payment` (service-specific)
- **Credits**: Only session counts for appointments
- **Access**: Tied to specific services
- **Webhook**: Required `service_id` parameter

#### **New System** (Universal Packages)

- **Scope**: Universal content access (appointments + content + events)
- **Tables**: `universal_packages`, `package_access_rules`, `universal_package_purchases`
- **Function**: `process_universal_package_purchase_payment` (creator-wide)
- **Credits**: Multi-type credits (appointments, content, events)
- **Access**: Cross-service, content-type based, or specific content
- **Webhook**: Only requires `package_id` (no service dependency)

### Migration Path

```typescript
// OLD: Service Package Purchase
const oldPurchaseFlow = {
  metadata: {
    purchase_type: "package",
    package_id: "uuid",
    service_id: "uuid", // REQUIRED
  },
  webhook_function: "process_package_purchase_payment",
  scope: "single service only",
};

// NEW: Universal Package Purchase
const newPurchaseFlow = {
  metadata: {
    purchase_type: "universal_package",
    package_id: "uuid",
    // service_id: NOT REQUIRED
    creator_id: "uuid",
    package_type: "hybrid_credits",
    appointment_credits: 5,
    content_credits: 20,
    event_credits: 2,
  },
  webhook_function: "process_universal_package_purchase_payment",
  scope: "entire creator ecosystem",
};
```

### Backward Compatibility

The old system continues to work alongside the new system:

- Existing service packages remain functional
- Old webhook handlers still process legacy purchases
- Users can have both types of packages simultaneously
- No migration required for existing data

## Database Schema Changes

### New Tables

#### `universal_packages`

```sql
CREATE TABLE universal_packages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id uuid REFERENCES auth.users(id),

    -- Package metadata
    name text NOT NULL,
    description text,
    package_type package_access_type_enum, -- NEW ENUM

    -- Pricing
    price numeric(10,2),
    currency text DEFAULT 'usd',

    -- Duration & billing
    duration_weeks integer,
    is_recurring boolean DEFAULT false,
    recurring_interval_weeks integer,

    -- Credit allocations (NEW)
    total_appointment_credits integer DEFAULT 0,
    total_content_credits integer DEFAULT 0,
    total_event_credits integer DEFAULT 0,

    -- Access patterns (NEW)
    appointment_access_pattern access_pattern_enum,
    content_access_pattern access_pattern_enum,
    event_access_pattern access_pattern_enum,

    -- Stripe integration
    stripe_product_id text,
    stripe_price_id text,

    -- Status & config
    is_active boolean DEFAULT true,
    is_featured boolean DEFAULT false,
    is_user_defined boolean DEFAULT false,
    template_package_id uuid REFERENCES universal_packages(id),
    configuration jsonb DEFAULT '{}',

    -- Timestamps
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);
```

#### `package_access_rules`

```sql
CREATE TABLE package_access_rules (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    package_id uuid REFERENCES universal_packages(id),

    -- What can be accessed (one of these)
    service_id uuid REFERENCES services(id), -- Legacy: specific service
    content_id uuid, -- Specific content piece
    post_id uuid REFERENCES posts(id), -- Specific post
    post_type text, -- All content of this type
    event_id uuid, -- Specific event

    -- How it can be accessed
    access_type access_pattern_enum,
    credits_required integer DEFAULT 1,

    -- Usage limits
    daily_limit integer,
    weekly_limit integer,
    monthly_limit integer,
    priority integer DEFAULT 0,

    created_at timestamptz DEFAULT now()
);
```

#### `universal_package_purchases`

```sql
CREATE TABLE universal_package_purchases (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_id uuid REFERENCES purchases(id),
    package_id uuid REFERENCES universal_packages(id),

    -- Current credit balances
    appointment_credits_remaining integer DEFAULT 0,
    content_credits_remaining integer DEFAULT 0,
    event_credits_remaining integer DEFAULT 0,

    -- Subscription tracking
    is_recurring boolean DEFAULT false,
    current_period_start timestamptz,
    current_period_end timestamptz,
    next_billing_date timestamptz,

    -- Lifecycle
    activated_at timestamptz DEFAULT now(),
    expires_at timestamptz,
    status text DEFAULT 'active',

    -- Usage analytics
    total_appointments_used integer DEFAULT 0,
    total_content_accessed integer DEFAULT 0,
    total_events_attended integer DEFAULT 0,

    -- Credit refresh tracking
    last_credit_refresh_at timestamptz,
    next_credit_refresh_at timestamptz,

    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);
```

#### `package_usage_log`

```sql
CREATE TABLE package_usage_log (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    package_purchase_id uuid REFERENCES universal_package_purchases(id),

    access_type text, -- 'appointment', 'content', 'event', 'post'
    resource_id uuid, -- ID of accessed resource
    credits_used integer DEFAULT 1,

    access_date timestamptz DEFAULT now(),
    metadata jsonb DEFAULT '{}',
    created_at timestamptz DEFAULT now()
);
```

### New Enums

```sql
-- Package access types
CREATE TYPE package_access_type_enum AS ENUM (
    'appointments_only',    -- Traditional appointment packages
    'content_credits',      -- Fixed content access credits
    'unlimited_content',    -- Netflix-style unlimited access
    'hybrid_credits',       -- Mix of appointments + content
    'full_access',         -- Everything unlimited
    'custom_bundle'        -- User-defined combinations
);

-- Access patterns for different content types
CREATE TYPE access_pattern_enum AS ENUM (
    'pay_per_use',         -- 1 credit per access
    'unlimited',           -- No credits required
    'daily_allowance',     -- Refresh daily
    'weekly_allowance',    -- Refresh weekly
    'monthly_allowance',   -- Refresh monthly
    'bi_weekly_allowance'  -- Refresh bi-weekly
);
```

## API Functions & Database Calls

### Core Package Functions

#### 1. Create Default Templates

```typescript
// Function: create_default_package_templates()
const createTemplates = async (creatorId?: string) => {
  const { data, error } = await supabase.rpc(
    "create_default_package_templates",
    {
      p_creator_id: creatorId || null,
    }
  );

  if (error) throw error;

  return data as PackageTemplateCreationResult;
};

// Result structure:
interface PackageTemplateCreationResult {
  success: boolean;
  creator_id: string;
  template_ids: string[];
  templates_created: number;
}
```

#### 2. Purchase Universal Package

```typescript
// Function: purchase_universal_package()
const purchasePackage = async (packageId: string, paymentIntentId?: string) => {
  const { data, error } = await supabase.rpc("purchase_universal_package", {
    p_package_id: packageId,
    p_stripe_payment_intent_id: paymentIntentId,
  });

  if (error) throw error;

  return data as PurchaseUniversalPackageResult;
};

// Result structure:
interface PurchaseUniversalPackageResult {
  success: boolean;
  purchase_id: string;
  package_purchase_id: string;
  package_id: string;
  expires_at: string | null;
  appointment_credits: number;
  content_credits: number;
  event_credits: number;
}
```

#### 3. Check Content Access

```typescript
// Function: can_access_with_package()
const checkAccess = async (accessType: string, resourceId: string) => {
  const { data, error } = await supabase.rpc("can_access_with_package", {
    p_access_type: accessType, // 'appointment', 'content', 'event', 'post'
    p_resource_id: resourceId,
  });

  if (error) throw error;

  return data as PackageAccessCheckResult;
};

// Result structure:
interface PackageAccessCheckResult {
  can_access: boolean;
  package_purchase_id?: string;
  credits_required: number;
  access_type: string;
  daily_limit_reached?: boolean;
  weekly_limit_reached?: boolean;
  monthly_limit_reached?: boolean;
}
```

#### 4. Use Package Credits

```typescript
// Function: use_package_credits()
const useCredits = async (
  packagePurchaseId: string,
  accessType: string,
  resourceId: string,
  creditsUsed: number = 1
) => {
  const { data, error } = await supabase.rpc("use_package_credits", {
    p_package_purchase_id: packagePurchaseId,
    p_access_type: accessType,
    p_resource_id: resourceId,
    p_credits_used: creditsUsed,
  });

  if (error) throw error;

  return data as CreditUsageResult;
};

// Result structure:
interface CreditUsageResult {
  success: boolean;
  credits_used: number;
  remaining_credits: number;
  access_type: string;
}
```

#### 5. Add Package Access Rules

```typescript
// Function: add_package_access_rules()
const addAccessRules = async (packageId: string, rules: AccessRule[]) => {
  const { data, error } = await supabase.rpc("add_package_access_rules", {
    p_package_id: packageId,
    p_access_rules: JSON.stringify(rules),
  });

  if (error) throw error;

  return data as AccessRulesCreationResult;
};

// Access rule structure:
interface AccessRule {
  service_id?: string;
  content_id?: string;
  post_id?: string;
  post_type?: string;
  event_id?: string;
  access_type: AccessPattern;
  credits_required?: number;
  daily_limit?: number;
  weekly_limit?: number;
  monthly_limit?: number;
  priority?: number;
}
```

### Query Functions for Data Fetching

#### 1. Get User's Packages

```typescript
const getUserPackages = async (userId: string) => {
  const { data, error } = await supabase
    .from("universal_package_purchases")
    .select(
      `
      *,
      package:universal_packages(*),
      purchase:purchases(*)
    `
    )
    .eq("purchase.user_id", userId)
    .eq("status", "active");

  return data as UserPackageWithDetails[];
};
```

#### 2. Get Creator's Packages

```typescript
const getCreatorPackages = async (creatorId: string) => {
  const { data, error } = await supabase
    .from("universal_packages")
    .select(
      `
      *,
      access_rules:package_access_rules(*),
      purchases_count:universal_package_purchases(count)
    `
    )
    .eq("creator_id", creatorId)
    .eq("is_active", true);

  return data as CreatorPackageWithStats[];
};
```

#### 3. Get Package Details

```typescript
// Function: get_package_purchase_details()
const getPackageDetails = async (packagePurchaseId: string) => {
  const { data, error } = await supabase.rpc("get_package_purchase_details", {
    p_package_purchase_id: packagePurchaseId,
  });

  if (error) throw error;

  return data as PackageDetailsResult;
};

// Result includes:
interface PackageDetailsResult {
  package_purchase: {
    id: string;
    appointment_credits_remaining: number;
    content_credits_remaining: number;
    event_credits_remaining: number;
    expires_at: string;
    status: string;
    // ... other fields
  };
  package: {
    id: string;
    name: string;
    description: string;
    package_type: string;
    // ... other fields
  };
  creator: {
    id: string;
    full_name: string;
    avatar_url: string;
  };
  access_rules: AccessRule[];
  usage_stats: {
    credits_used_percentage: {
      appointments: number;
      content: number;
      events: number;
    };
  };
}
```

## TypeScript Types & Interfaces

### Core Package Types

```typescript
// Universal package definition
export interface UniversalPackage {
  id: string;
  creator_id: string;
  name: string;
  description: string | null;
  package_type: PackageAccessType;
  price: number;
  currency: string;
  duration_weeks: number | null;
  is_recurring: boolean;
  recurring_interval_weeks: number | null;
  total_appointment_credits: number;
  total_content_credits: number;
  total_event_credits: number;
  appointment_access_pattern: AccessPattern;
  content_access_pattern: AccessPattern;
  event_access_pattern: AccessPattern;
  stripe_product_id: string | null;
  stripe_price_id: string | null;
  is_active: boolean;
  is_featured: boolean;
  is_user_defined: boolean;
  template_package_id: string | null;
  configuration: Record<string, any>;
  created_at: string;
  updated_at: string;
}

// Package access rule
export interface PackageAccessRule {
  id: string;
  package_id: string;
  service_id: string | null;
  content_id: string | null;
  post_id: string | null;
  post_type: string | null;
  event_id: string | null;
  access_type: AccessPattern;
  credits_required: number;
  daily_limit: number | null;
  weekly_limit: number | null;
  monthly_limit: number | null;
  priority: number;
  created_at: string;
}

// User's package purchase
export interface UniversalPackagePurchase {
  id: string;
  purchase_id: string;
  package_id: string;
  appointment_credits_remaining: number;
  content_credits_remaining: number;
  event_credits_remaining: number;
  is_recurring: boolean;
  current_period_start: string | null;
  current_period_end: string | null;
  next_billing_date: string | null;
  activated_at: string;
  expires_at: string | null;
  status: PackageStatus;
  total_appointments_used: number;
  total_content_accessed: number;
  total_events_attended: number;
  last_credit_refresh_at: string | null;
  next_credit_refresh_at: string | null;
  created_at: string;
  updated_at: string;
}

// Enums
export type PackageAccessType =
  | "appointments_only"
  | "content_credits"
  | "unlimited_content"
  | "hybrid_credits"
  | "full_access"
  | "custom_bundle";

export type AccessPattern =
  | "pay_per_use"
  | "unlimited"
  | "daily_allowance"
  | "weekly_allowance"
  | "monthly_allowance"
  | "bi_weekly_allowance";

export type PackageStatus = "active" | "expired" | "canceled" | "suspended";
export type AccessResourceType = "appointment" | "content" | "event" | "post";
```

### Enhanced Display Types

```typescript
// Package with full details for user dashboard
export interface UserPackageWithDetails extends UniversalPackagePurchase {
  package: UniversalPackage;
  access_rules: PackageAccessRule[];
  usage_this_month: {
    appointments_used: number;
    content_accessed: number;
    events_attended: number;
    total_credits_used: number;
  };
  progress_percentage: {
    appointments: number;
    content: number;
    events: number;
    overall: number;
  };
}

// Package for creator dashboard
export interface CreatorPackageWithStats extends UniversalPackage {
  access_rules: PackageAccessRule[];
  active_subscribers: number;
  total_revenue: number;
  monthly_revenue: number;
  average_credits_used: number;
  most_accessed_content_type: string;
  churn_rate: number;
}

// Package analytics data
export interface PackageAnalytics {
  package_id: string;
  package_name: string;
  subscribers_count: number;
  revenue_total: number;
  revenue_monthly: number;
  credits_utilization: {
    appointments: number;
    content: number;
    events: number;
    overall: number;
  };
  popular_content: Array<{
    type: string;
    count: number;
    percentage: number;
  }>;
  user_behavior: {
    avg_session_duration: number;
    peak_usage_hours: number[];
    retention_rate: number;
  };
}
```

### Form & API Types

```typescript
// Package creation form data
export interface CreatePackageFormData {
  name: string;
  description: string;
  package_type: PackageAccessType;
  price: number;
  currency: string;
  duration_weeks: number | null;
  is_recurring: boolean;
  recurring_interval_weeks: number | null;
  appointment_credits: number;
  content_credits: number;
  event_credits: number;
  appointment_access_pattern: AccessPattern;
  content_access_pattern: AccessPattern;
  event_access_pattern: AccessPattern;
  access_rules: CreateAccessRuleData[];
  configuration: Record<string, any>;
}

// Access rule creation data
export interface CreateAccessRuleData {
  service_id?: string;
  content_id?: string;
  post_id?: string;
  post_type?: string;
  event_id?: string;
  access_type: AccessPattern;
  credits_required: number;
  daily_limit?: number;
  weekly_limit?: number;
  monthly_limit?: number;
  priority: number;
}

// Custom package builder data
export interface CustomPackageBuilderData {
  base_price: number;
  appointment_credit_price: number;
  content_credit_price: number;
  event_credit_price: number;
  duration_week_price: number;
  selected_appointment_credits: number;
  selected_content_credits: number;
  selected_event_credits: number;
  selected_duration_weeks: number;
  calculated_total_price: number;
}
```

### Hook Return Types

```typescript
// Hook for managing user packages
export interface UseUserPackagesReturn {
  packages: UserPackageWithDetails[];
  isLoading: boolean;
  error: Error | null;
  refetch: () => void;
  purchasePackage: (
    packageId: string
  ) => Promise<PurchaseUniversalPackageResult>;
  checkAccess: (
    accessType: AccessResourceType,
    resourceId: string
  ) => Promise<PackageAccessCheckResult>;
  useCredits: (
    packagePurchaseId: string,
    accessType: AccessResourceType,
    resourceId: string
  ) => Promise<CreditUsageResult>;
}

// Hook for creator package management
export interface UseCreatorPackagesReturn {
  packages: CreatorPackageWithStats[];
  analytics: PackageAnalytics[];
  isLoading: boolean;
  error: Error | null;
  createPackage: (data: CreatePackageFormData) => Promise<UniversalPackage>;
  updatePackage: (
    packageId: string,
    data: Partial<CreatePackageFormData>
  ) => Promise<UniversalPackage>;
  addAccessRules: (
    packageId: string,
    rules: CreateAccessRuleData[]
  ) => Promise<AccessRulesCreationResult>;
  createDefaultTemplates: () => Promise<PackageTemplateCreationResult>;
}
```

## Stripe Integration Implementation

### Payment Intent Creation

```typescript
// Frontend: Prepare package for checkout
const preparePackageCheckout = async (packageId: string) => {
  const { data, error } = await supabase.rpc("prepare_package_for_stripe", {
    p_package_id: packageId,
  });

  if (error) throw error;

  return data as PackageStripeCheckoutData;
};

// Create payment intent with proper metadata
const createPaymentIntent = async (packageData: PackageStripeCheckoutData) => {
  const response = await fetch("/api/stripe/create-payment-intent", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      amount: packageData.price * 100, // Convert to cents
      currency: packageData.currency,
      metadata: packageData.stripe_metadata,
      automatic_payment_methods: { enabled: true },
    }),
  });

  return response.json();
};
```

### Webhook Handler Implementation

```typescript
// api/stripe/webhook.ts - Enhanced webhook handler
import { UniversalPackageStripeMetadata } from "@/types/universal-package-webhook-types";

export async function handleUniversalPackageWebhook(
  paymentIntent: Stripe.PaymentIntent
): Promise<UniversalPackageWebhookResult> {
  const metadata = paymentIntent.metadata as UniversalPackageStripeMetadata;

  // Validate metadata
  if (metadata.purchase_type !== "universal_package") {
    throw new Error("Invalid purchase type for universal package webhook");
  }

  // Get purchase record
  const { data: purchase, error: purchaseError } = await supabase
    .from("purchases")
    .select("id, user_id")
    .eq("stripe_payment_intent_id", paymentIntent.id)
    .single();

  if (purchaseError || !purchase) {
    throw new Error(`Purchase not found: ${paymentIntent.id}`);
  }

  // Process with new webhook function
  const { data: result, error: processError } = await supabase.rpc(
    "process_universal_package_purchase_payment",
    {
      p_purchase_id: purchase.id,
      p_payment_intent_id: paymentIntent.id,
      p_package_id: metadata.package_id,
    }
  );

  if (processError) {
    throw new Error(`Processing failed: ${processError.message}`);
  }

  return {
    purchaseId: purchase.id,
    userId: purchase.user_id,
    packageId: metadata.package_id,
    packageType: metadata.package_type,
    status: "completed",
    rpcResult: result,
  };
}
```

### Frontend Checkout Component

```typescript
// components/PackageCheckout.tsx
import {
  Elements,
  PaymentElement,
  useStripe,
  useElements,
} from "@stripe/react-stripe-js";

interface PackageCheckoutProps {
  package: UniversalPackage;
  onSuccess: (result: PurchaseUniversalPackageResult) => void;
}

const PackageCheckout: React.FC<PackageCheckoutProps> = ({
  package: pkg,
  onSuccess,
}) => {
  const stripe = useStripe();
  const elements = useElements();
  const [isProcessing, setIsProcessing] = useState(false);
  const [clientSecret, setClientSecret] = useState<string>("");

  // Initialize payment intent
  useEffect(() => {
    const initializePayment = async () => {
      try {
        const checkoutData = await preparePackageCheckout(pkg.id);
        const paymentIntent = await createPaymentIntent(checkoutData);
        setClientSecret(paymentIntent.client_secret);
      } catch (error) {
        console.error("Payment initialization failed:", error);
      }
    };

    initializePayment();
  }, [pkg.id]);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();

    if (!stripe || !elements) return;

    setIsProcessing(true);

    const { error, paymentIntent } = await stripe.confirmPayment({
      elements,
      confirmParams: {
        return_url: `${window.location.origin}/packages/success`,
      },
      redirect: "if_required",
    });

    if (error) {
      console.error("Payment failed:", error);
      setIsProcessing(false);
    } else if (paymentIntent?.status === "succeeded") {
      // Payment succeeded, webhook will process the package purchase
      onSuccess({
        success: true,
        purchase_id: paymentIntent.id,
        package_purchase_id: "", // Will be filled by webhook
        package_id: pkg.id,
        expires_at: null, // Will be calculated by webhook
        appointment_credits: pkg.total_appointment_credits,
        content_credits: pkg.total_content_credits,
        event_credits: pkg.total_event_credits,
      });
    }

    setIsProcessing(false);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="p-4 border rounded-lg">
        <h3 className="font-semibold">{pkg.name}</h3>
        <p className="text-gray-600">{pkg.description}</p>
        <div className="mt-2 space-y-1 text-sm">
          <div>💬 {pkg.total_appointment_credits} appointment credits</div>
          <div>📚 {pkg.total_content_credits} content credits</div>
          <div>🎪 {pkg.total_event_credits} event credits</div>
          <div className="font-semibold">${pkg.price}</div>
        </div>
      </div>

      {clientSecret && (
        <PaymentElement
          options={{
            layout: "tabs",
          }}
        />
      )}

      <button
        type="submit"
        disabled={!stripe || isProcessing}
        className="w-full bg-blue-600 text-white py-2 px-4 rounded-md disabled:opacity-50"
      >
        {isProcessing ? "Processing..." : `Purchase for $${pkg.price}`}
      </button>
    </form>
  );
};

// Wrapper with Stripe Elements
const PackageCheckoutWrapper: React.FC<PackageCheckoutProps> = (props) => {
  return (
    <Elements stripe={stripePromise}>
      <PackageCheckout {...props} />
    </Elements>
  );
};
```

## State Management with Jotai

### Package Atoms

```typescript
// atoms/packageAtoms.ts
import { atom } from "jotai";
import {
  UniversalPackage,
  UserPackageWithDetails,
  PackageAccessCheckResult,
} from "@/types/universal-packages";

// User's active packages
export const userPackagesAtom = atom<UserPackageWithDetails[]>([]);

// Currently selected package for purchase
export const selectedPackageAtom = atom<UniversalPackage | null>(null);

// Package access cache for content
export const packageAccessCacheAtom = atom<
  Record<string, PackageAccessCheckResult>
>({});

// Package purchase flow state
export const packagePurchaseFlowAtom = atom<{
  step:
    | "select"
    | "customize"
    | "checkout"
    | "processing"
    | "success"
    | "error";
  packageId: string | null;
  customization: CustomPackageBuilderData | null;
  error: string | null;
}>({
  step: "select",
  packageId: null,
  customization: null,
  error: null,
});

// Creator's packages (for creators)
export const creatorPackagesAtom = atom<CreatorPackageWithStats[]>([]);

// Package analytics (for creators)
export const packageAnalyticsAtom = atom<PackageAnalytics[]>([]);
```

### Derived Atoms

```typescript
// Derived atoms for computed values
export const activeUserPackagesAtom = atom((get) =>
  get(userPackagesAtom).filter((pkg) => pkg.status === "active")
);

export const expiredUserPackagesAtom = atom((get) =>
  get(userPackagesAtom).filter((pkg) => pkg.status === "expired")
);

export const totalCreditsRemainingAtom = atom((get) => {
  const packages = get(activeUserPackagesAtom);
  return packages.reduce(
    (total, pkg) => ({
      appointments: total.appointments + pkg.appointment_credits_remaining,
      content: total.content + pkg.content_credits_remaining,
      events: total.events + pkg.event_credits_remaining,
    }),
    { appointments: 0, content: 0, events: 0 }
  );
});

export const canAccessContentAtom = atom(
  (get) => (accessType: string, resourceId: string) => {
    const cache = get(packageAccessCacheAtom);
    const cacheKey = `${accessType}:${resourceId}`;
    return cache[cacheKey]?.can_access || false;
  }
);
```

### Package Actions

```typescript
// atoms/packageActions.ts
import { atom } from "jotai";

// Action to purchase a package
export const purchasePackageAction = atom(
  null,
  async (
    get,
    set,
    {
      packageId,
      customization,
    }: {
      packageId: string;
      customization?: CustomPackageBuilderData;
    }
  ) => {
    set(packagePurchaseFlowAtom, (prev) => ({
      ...prev,
      step: "processing",
      packageId,
    }));

    try {
      // If it's a custom package, create it first
      if (customization) {
        const customPackage = await createUserDefinedPackage(customization);
        packageId = customPackage.package_id;
      }

      // Prepare for Stripe checkout
      const checkoutData = await preparePackageCheckout(packageId);
      const paymentIntent = await createPaymentIntent(checkoutData);

      set(packagePurchaseFlowAtom, (prev) => ({
        ...prev,
        step: "checkout",
      }));

      return { checkoutData, paymentIntent };
    } catch (error) {
      set(packagePurchaseFlowAtom, (prev) => ({
        ...prev,
        step: "error",
        error: error.message,
      }));
      throw error;
    }
  }
);

// Action to use package credits
export const usePackageCreditsAction = atom(
  null,
  async (
    get,
    set,
    {
      packagePurchaseId,
      accessType,
      resourceId,
      creditsUsed = 1,
    }: {
      packagePurchaseId: string;
      accessType: AccessResourceType;
      resourceId: string;
      creditsUsed?: number;
    }
  ) => {
    try {
      const result = await useCredits(
        packagePurchaseId,
        accessType,
        resourceId,
        creditsUsed
      );

      // Update local state
      set(userPackagesAtom, (prev) =>
        prev.map((pkg) =>
          pkg.id === packagePurchaseId
            ? {
                ...pkg,
                [`${accessType}_credits_remaining`]: result.remaining_credits,
                [`total_${accessType}s_used`]:
                  pkg[`total_${accessType}s_used`] + creditsUsed,
              }
            : pkg
        )
      );

      return result;
    } catch (error) {
      console.error("Credit usage failed:", error);
      throw error;
    }
  }
);

// Action to check access for content
export const checkContentAccessAction = atom(
  null,
  async (
    get,
    set,
    {
      accessType,
      resourceId,
    }: {
      accessType: AccessResourceType;
      resourceId: string;
    }
  ) => {
    const cacheKey = `${accessType}:${resourceId}`;

    try {
      const result = await checkAccess(accessType, resourceId);

      // Cache the result
      set(packageAccessCacheAtom, (prev) => ({
        ...prev,
        [cacheKey]: result,
      }));

      return result;
    } catch (error) {
      console.error("Access check failed:", error);
      throw error;
    }
  }
);
```

## TanStack Query Integration

### Package Queries

```typescript
// hooks/usePackageQueries.ts
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";

// Query keys
export const packageQueryKeys = {
  all: ["packages"] as const,
  user: (userId: string) => [...packageQueryKeys.all, "user", userId] as const,
  creator: (creatorId: string) =>
    [...packageQueryKeys.all, "creator", creatorId] as const,
  public: () => [...packageQueryKeys.all, "public"] as const,
  details: (packageId: string) =>
    [...packageQueryKeys.all, "details", packageId] as const,
  analytics: (creatorId: string) =>
    [...packageQueryKeys.all, "analytics", creatorId] as const,
  access: (accessType: string, resourceId: string) =>
    [...packageQueryKeys.all, "access", accessType, resourceId] as const,
};

// User packages query
export const useUserPackages = (userId: string) => {
  return useQuery({
    queryKey: packageQueryKeys.user(userId),
    queryFn: () => getUserPackages(userId),
    staleTime: 5 * 60 * 1000, // 5 minutes
    gcTime: 10 * 60 * 1000, // 10 minutes
  });
};

// Creator packages query
export const useCreatorPackages = (creatorId: string) => {
  return useQuery({
    queryKey: packageQueryKeys.creator(creatorId),
    queryFn: () => getCreatorPackages(creatorId),
    staleTime: 2 * 60 * 1000, // 2 minutes
  });
};

// Public packages query (for marketplace)
export const usePublicPackages = (filters?: {
  packageType?: PackageAccessType;
  priceRange?: [number, number];
  creatorId?: string;
}) => {
  return useQuery({
    queryKey: [...packageQueryKeys.public(), filters],
    queryFn: () => getPublicPackages(filters),
    staleTime: 10 * 60 * 1000, // 10 minutes
  });
};

// Package details query
export const usePackageDetails = (packagePurchaseId: string) => {
  return useQuery({
    queryKey: packageQueryKeys.details(packagePurchaseId),
    queryFn: () => getPackageDetails(packagePurchaseId),
    enabled: !!packagePurchaseId,
    staleTime: 1 * 60 * 1000, // 1 minute
  });
};

// Package analytics query
export const usePackageAnalytics = (creatorId: string) => {
  return useQuery({
    queryKey: packageQueryKeys.analytics(creatorId),
    queryFn: () => getPackageAnalytics(creatorId),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
};

// Content access check query
export const useContentAccess = (
  accessType: AccessResourceType,
  resourceId: string
) => {
  return useQuery({
    queryKey: packageQueryKeys.access(accessType, resourceId),
    queryFn: () => checkAccess(accessType, resourceId),
    enabled: !!accessType && !!resourceId,
    staleTime: 30 * 1000, // 30 seconds
    gcTime: 2 * 60 * 1000, // 2 minutes
  });
};
```

### Package Mutations

```typescript
// Package purchase mutation
export const usePurchasePackage = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      packageId,
      paymentIntentId,
    }: {
      packageId: string;
      paymentIntentId?: string;
    }) => purchasePackage(packageId, paymentIntentId),
    onSuccess: (result, variables) => {
      // Invalidate user packages query
      queryClient.invalidateQueries({
        queryKey: packageQueryKeys.user(result.user_id),
      });

      // Update analytics
      queryClient.invalidateQueries({
        queryKey: packageQueryKeys.analytics,
      });
    },
  });
};

// Credit usage mutation
export const usePackageCredits = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      packagePurchaseId,
      accessType,
      resourceId,
      creditsUsed,
    }: {
      packagePurchaseId: string;
      accessType: AccessResourceType;
      resourceId: string;
      creditsUsed?: number;
    }) => useCredits(packagePurchaseId, accessType, resourceId, creditsUsed),
    onSuccess: (result, variables) => {
      // Update package details
      queryClient.invalidateQueries({
        queryKey: packageQueryKeys.details(variables.packagePurchaseId),
      });

      // Clear access cache for this content
      queryClient.invalidateQueries({
        queryKey: packageQueryKeys.access(
          variables.accessType,
          variables.resourceId
        ),
      });
    },
  });
};

// Package creation mutation
export const useCreatePackage = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreatePackageFormData) => createPackage(data),
    onSuccess: (result, variables) => {
      // Invalidate creator packages
      queryClient.invalidateQueries({
        queryKey: packageQueryKeys.creator(result.creator_id),
      });

      // Invalidate public packages
      queryClient.invalidateQueries({
        queryKey: packageQueryKeys.public(),
      });
    },
  });
};

// Template creation mutation
export const useCreateDefaultTemplates = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (creatorId?: string) => createTemplates(creatorId),
    onSuccess: (result) => {
      // Invalidate creator packages
      queryClient.invalidateQueries({
        queryKey: packageQueryKeys.creator(result.creator_id),
      });
    },
  });
};
```

### Custom Hooks

```typescript
// Custom hook for package management
export const usePackageManager = (creatorId: string) => {
  const { data: packages, isLoading, error } = useCreatorPackages(creatorId);
  const { data: analytics } = usePackageAnalytics(creatorId);
  const createPackageMutation = useCreatePackage();
  const createTemplatesMutation = useCreateDefaultTemplates();

  const createPackage = useCallback(
    async (data: CreatePackageFormData) => {
      return createPackageMutation.mutateAsync(data);
    },
    [createPackageMutation]
  );

  const createDefaultTemplates = useCallback(async () => {
    return createTemplatesMutation.mutateAsync(creatorId);
  }, [createTemplatesMutation, creatorId]);

  return {
    packages: packages || [],
    analytics: analytics || [],
    isLoading,
    error,
    createPackage,
    createDefaultTemplates,
    isCreatingPackage: createPackageMutation.isPending,
    isCreatingTemplates: createTemplatesMutation.isPending,
  };
};

// Custom hook for user package management
export const useUserPackageManager = (userId: string) => {
  const { data: packages, isLoading, error, refetch } = useUserPackages(userId);
  const purchaseMutation = usePurchasePackage();
  const creditsMutation = usePackageCredits();

  const purchasePackage = useCallback(
    async (packageId: string) => {
      return purchaseMutation.mutateAsync({ packageId });
    },
    [purchaseMutation]
  );

  const useCredits = useCallback(
    async (
      packagePurchaseId: string,
      accessType: AccessResourceType,
      resourceId: string
    ) => {
      return creditsMutation.mutateAsync({
        packagePurchaseId,
        accessType,
        resourceId,
      });
    },
    [creditsMutation]
  );

  const checkAccess = useCallback(
    (accessType: AccessResourceType, resourceId: string) => {
      // This would use the access query
      const accessQuery = useContentAccess(accessType, resourceId);
      return accessQuery.data?.can_access || false;
    },
    []
  );

  return {
    packages: packages || [],
    isLoading,
    error,
    refetch,
    purchasePackage,
    useCredits,
    checkAccess,
    isPurchasing: purchaseMutation.isPending,
    isUsingCredits: creditsMutation.isPending,
  };
};
```

## Frontend Component Architecture

### Package Selection Components

```typescript
// components/packages/PackageCard.tsx
interface PackageCardProps {
  package: UniversalPackage;
  onSelect?: (packageId: string) => void;
  onCustomize?: (packageId: string) => void;
  showPurchaseButton?: boolean;
  showCustomizeButton?: boolean;
  className?: string;
}

const PackageCard: React.FC<PackageCardProps> = ({
  package: pkg,
  onSelect,
  onCustomize,
  showPurchaseButton = true,
  showCustomizeButton = false,
  className = "",
}) => {
  const badgeColor = {
    hybrid_credits: "bg-purple-100 text-purple-800",
    unlimited_content: "bg-green-100 text-green-800",
    content_credits: "bg-blue-100 text-blue-800",
    appointments_only: "bg-orange-100 text-orange-800",
    full_access: "bg-gold-100 text-gold-800",
    custom_bundle: "bg-gray-100 text-gray-800",
  };

  const isRecurring = pkg.is_recurring;
  const billingText = isRecurring
    ? `Every ${pkg.recurring_interval_weeks} weeks`
    : `${pkg.duration_weeks} weeks access`;

  return (
    <div
      className={`border rounded-lg p-6 hover:shadow-lg transition-shadow ${className}`}
    >
      {/* Header */}
      <div className="flex justify-between items-start mb-4">
        <div>
          <h3 className="text-xl font-semibold">{pkg.name}</h3>
          <span
            className={`inline-block px-2 py-1 rounded-full text-xs ${
              badgeColor[pkg.package_type]
            }`}
          >
            {pkg.package_type.replace("_", " ")}
          </span>
        </div>
        {pkg.is_featured && (
          <span className="bg-yellow-100 text-yellow-800 px-2 py-1 rounded-full text-xs">
            Featured
          </span>
        )}
      </div>

      {/* Description */}
      {pkg.description && (
        <p className="text-gray-600 mb-4">{pkg.description}</p>
      )}

      {/* Credits breakdown */}
      <div className="space-y-2 mb-4">
        {pkg.total_appointment_credits > 0 && (
          <div className="flex items-center text-sm">
            <span className="mr-2">💬</span>
            <span>{pkg.total_appointment_credits} appointment credits</span>
          </div>
        )}
        {pkg.total_content_credits > 0 && (
          <div className="flex items-center text-sm">
            <span className="mr-2">📚</span>
            <span>
              {pkg.content_access_pattern === "unlimited"
                ? "Unlimited content access"
                : `${pkg.total_content_credits} content credits`}
            </span>
          </div>
        )}
        {pkg.total_event_credits > 0 && (
          <div className="flex items-center text-sm">
            <span className="mr-2">🎪</span>
            <span>
              {pkg.event_access_pattern === "unlimited"
                ? "Unlimited event access"
                : `${pkg.total_event_credits} event credits`}
            </span>
          </div>
        )}
      </div>

      {/* Pricing */}
      <div className="border-t pt-4">
        <div className="flex items-baseline justify-between">
          <div>
            <span className="text-2xl font-bold">${pkg.price}</span>
            <span className="text-gray-500 ml-2">{billingText}</span>
          </div>
          {isRecurring && (
            <span className="text-xs text-green-600 bg-green-50 px-2 py-1 rounded">
              Subscription
            </span>
          )}
        </div>

        {/* Action buttons */}
        <div className="mt-4 space-y-2">
          {showPurchaseButton && (
            <button
              onClick={() => onSelect?.(pkg.id)}
              className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 transition-colors"
            >
              {pkg.package_type === "custom_bundle"
                ? "Customize & Purchase"
                : "Purchase Package"}
            </button>
          )}

          {showCustomizeButton && pkg.configuration?.customizable && (
            <button
              onClick={() => onCustomize?.(pkg.id)}
              className="w-full border border-gray-300 text-gray-700 py-2 px-4 rounded-md hover:bg-gray-50 transition-colors"
            >
              Customize This Package
            </button>
          )}
        </div>
      </div>
    </div>
  );
};
```

### Custom Package Builder

```typescript
// components/packages/CustomPackageBuilder.tsx
interface CustomPackageBuilderProps {
  templatePackage: UniversalPackage;
  onComplete: (data: CustomPackageBuilderData) => void;
  onCancel: () => void;
}

const CustomPackageBuilder: React.FC<CustomPackageBuilderProps> = ({
  templatePackage,
  onComplete,
  onCancel,
}) => {
  const config = templatePackage.configuration as CustomPackageConfig;

  const [builderData, setBuilderData] = useState<CustomPackageBuilderData>({
    base_price: config.base_price || 10,
    appointment_credit_price: config.appointment_credit_price || 30,
    content_credit_price: config.content_credit_price || 3,
    event_credit_price: config.event_credit_price || 20,
    duration_week_price: config.duration_week_price || 2,
    selected_appointment_credits: 0,
    selected_content_credits: 10,
    selected_event_credits: 0,
    selected_duration_weeks: 4,
    calculated_total_price: 0,
  });

  // Calculate total price whenever selections change
  useEffect(() => {
    const totalPrice =
      builderData.base_price +
      builderData.selected_appointment_credits *
        builderData.appointment_credit_price +
      builderData.selected_content_credits * builderData.content_credit_price +
      builderData.selected_event_credits * builderData.event_credit_price +
      builderData.selected_duration_weeks * builderData.duration_week_price;

    setBuilderData((prev) => ({
      ...prev,
      calculated_total_price: Math.round(totalPrice * 100) / 100, // Round to 2 decimals
    }));
  }, [
    builderData.selected_appointment_credits,
    builderData.selected_content_credits,
    builderData.selected_event_credits,
    builderData.selected_duration_weeks,
    builderData.base_price,
    builderData.appointment_credit_price,
    builderData.content_credit_price,
    builderData.event_credit_price,
    builderData.duration_week_price,
  ]);

  const updateSelection = (field: string, value: number) => {
    setBuilderData((prev) => ({
      ...prev,
      [field]: value,
    }));
  };

  const handleComplete = () => {
    onComplete(builderData);
  };

  return (
    <div className="max-w-2xl mx-auto bg-white rounded-lg shadow-lg p-6">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">Build Your Perfect Package</h2>
        <button
          onClick={onCancel}
          className="text-gray-500 hover:text-gray-700"
        >
          ✕
        </button>
      </div>

      {/* Credit selectors */}
      <div className="space-y-6">
        {/* Appointment Credits */}
        <div className="border rounded-lg p-4">
          <div className="flex justify-between items-center mb-3">
            <div>
              <h3 className="font-semibold">💬 Appointment Credits</h3>
              <p className="text-sm text-gray-600">
                1:1 sessions with the creator
              </p>
            </div>
            <div className="text-right">
              <div className="text-lg font-semibold">
                $
                {builderData.selected_appointment_credits *
                  builderData.appointment_credit_price}
              </div>
              <div className="text-sm text-gray-500">
                ${builderData.appointment_credit_price} each
              </div>
            </div>
          </div>

          <div className="flex items-center space-x-4">
            <span className="text-sm">0</span>
            <input
              type="range"
              min={config.min_appointment_credits || 0}
              max={config.max_appointment_credits || 10}
              value={builderData.selected_appointment_credits}
              onChange={(e) =>
                updateSelection(
                  "selected_appointment_credits",
                  parseInt(e.target.value)
                )
              }
              className="flex-1"
            />
            <span className="text-sm">
              {config.max_appointment_credits || 10}
            </span>
            <div className="w-16 text-center font-semibold">
              {builderData.selected_appointment_credits}
            </div>
          </div>
        </div>

        {/* Content Credits */}
        <div className="border rounded-lg p-4">
          <div className="flex justify-between items-center mb-3">
            <div>
              <h3 className="font-semibold">📚 Content Credits</h3>
              <p className="text-sm text-gray-600">
                Access to courses, videos, articles
              </p>
            </div>
            <div className="text-right">
              <div className="text-lg font-semibold">
                $
                {builderData.selected_content_credits *
                  builderData.content_credit_price}
              </div>
              <div className="text-sm text-gray-500">
                ${builderData.content_credit_price} each
              </div>
            </div>
          </div>

          <div className="flex items-center space-x-4">
            <span className="text-sm">{config.min_content_credits || 5}</span>
            <input
              type="range"
              min={config.min_content_credits || 5}
              max={config.max_content_credits || 100}
              value={builderData.selected_content_credits}
              onChange={(e) =>
                updateSelection(
                  "selected_content_credits",
                  parseInt(e.target.value)
                )
              }
              className="flex-1"
            />
            <span className="text-sm">{config.max_content_credits || 100}</span>
            <div className="w-16 text-center font-semibold">
              {builderData.selected_content_credits}
            </div>
          </div>
        </div>

        {/* Event Credits */}
        <div className="border rounded-lg p-4">
          <div className="flex justify-between items-center mb-3">
            <div>
              <h3 className="font-semibold">🎪 Event Credits</h3>
              <p className="text-sm text-gray-600">Workshops, group sessions</p>
            </div>
            <div className="text-right">
              <div className="text-lg font-semibold">
                $
                {builderData.selected_event_credits *
                  builderData.event_credit_price}
              </div>
              <div className="text-sm text-gray-500">
                ${builderData.event_credit_price} each
              </div>
            </div>
          </div>

          <div className="flex items-center space-x-4">
            <span className="text-sm">0</span>
            <input
              type="range"
              min={config.min_event_credits || 0}
              max={config.max_event_credits || 10}
              value={builderData.selected_event_credits}
              onChange={(e) =>
                updateSelection(
                  "selected_event_credits",
                  parseInt(e.target.value)
                )
              }
              className="flex-1"
            />
            <span className="text-sm">{config.max_event_credits || 10}</span>
            <div className="w-16 text-center font-semibold">
              {builderData.selected_event_credits}
            </div>
          </div>
        </div>

        {/* Duration */}
        <div className="border rounded-lg p-4">
          <div className="flex justify-between items-center mb-3">
            <div>
              <h3 className="font-semibold">⏰ Package Duration</h3>
              <p className="text-sm text-gray-600">
                How long you'll have access
              </p>
            </div>
            <div className="text-right">
              <div className="text-lg font-semibold">
                $
                {builderData.selected_duration_weeks *
                  builderData.duration_week_price}
              </div>
              <div className="text-sm text-gray-500">
                ${builderData.duration_week_price} per week
              </div>
            </div>
          </div>

          <div className="flex items-center space-x-4">
            <span className="text-sm">{config.min_duration_weeks || 1}w</span>
            <input
              type="range"
              min={config.min_duration_weeks || 1}
              max={config.max_duration_weeks || 52}
              value={builderData.selected_duration_weeks}
              onChange={(e) =>
                updateSelection(
                  "selected_duration_weeks",
                  parseInt(e.target.value)
                )
              }
              className="flex-1"
            />
            <span className="text-sm">{config.max_duration_weeks || 52}w</span>
            <div className="w-16 text-center font-semibold">
              {builderData.selected_duration_weeks}w
            </div>
          </div>
        </div>
      </div>

      {/* Total and checkout */}
      <div className="mt-8 border-t pt-6">
        <div className="flex justify-between items-center mb-4">
          <div>
            <h3 className="text-lg font-semibold">Your Custom Package</h3>
            <p className="text-sm text-gray-600">
              {builderData.selected_appointment_credits +
                builderData.selected_content_credits +
                builderData.selected_event_credits}{" "}
              total credits • {builderData.selected_duration_weeks} weeks access
            </p>
          </div>
          <div className="text-right">
            <div className="text-2xl font-bold">
              ${builderData.calculated_total_price}
            </div>
            <div className="text-sm text-gray-500">
              Base: ${builderData.base_price} + Credits: $
              {builderData.calculated_total_price -
                builderData.base_price -
                builderData.selected_duration_weeks *
                  builderData.duration_week_price}{" "}
              + Duration: $
              {builderData.selected_duration_weeks *
                builderData.duration_week_price}
            </div>
          </div>
        </div>

        <div className="flex space-x-4">
          <button
            onClick={onCancel}
            className="flex-1 border border-gray-300 text-gray-700 py-3 px-4 rounded-md hover:bg-gray-50 transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={handleComplete}
            disabled={
              builderData.calculated_total_price < config.min_total_price
            }
            className="flex-1 bg-blue-600 text-white py-3 px-4 rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            Continue to Checkout
          </button>
        </div>
      </div>
    </div>
  );
};
```
