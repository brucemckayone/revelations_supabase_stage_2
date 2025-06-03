# Dual Purchase Options: Complete Implementation Guide

## Overview

The enhanced universal packages system now supports **dual purchase options**, allowing creators to offer the same package as both:

- **One-time purchase** (fixed duration)
- **Recurring subscription** (continuous billing)

This gives customers flexibility in how they want to pay and helps creators maximize revenue.

## Business Model Examples

### Example 1: Fitness Coach Package

```typescript
// "Personal Training Package" - same content, different payment options
const fitnessPackage = {
  name: "Personal Training Package",
  description: "Access to 1-on-1 training sessions",

  // One-time option: Buy 8 sessions upfront
  supports_one_time_purchase: true,
  one_time_price: 480.0, // $60 per session x 8
  one_time_duration_weeks: 8, // 8 weeks to use sessions

  // Recurring option: Monthly subscription
  supports_recurring_purchase: true,
  recurring_price: 180.0, // $180/month unlimited sessions
  recurring_billing_interval: "1 month",

  appointment_credits: 0, // Unlimited for recurring, tracked differently for one-time
};
```

### Example 2: Course Access Package

```typescript
const coursePackage = {
  name: "Photography Masterclass",
  description: "Complete photography course with weekly lessons",

  // One-time: Lifetime access
  supports_one_time_purchase: true,
  one_time_price: 297.0,
  one_time_duration_weeks: 520, // 10 years "lifetime"

  // Recurring: Monthly subscription
  supports_recurring_purchase: true,
  recurring_price: 29.0, // Much cheaper monthly
  recurring_billing_interval: "1 month",

  content_credits: 0, // Unlimited access to course content
};
```

## Database Schema Changes

### New Columns in `universal_packages`

```sql
-- Dual purchase support flags
supports_one_time_purchase boolean not null default true,
supports_recurring_purchase boolean not null default false,

-- Separate pricing for each option
one_time_price numeric(10,2),
recurring_price numeric(10,2),

-- Duration settings
one_time_duration_weeks integer,
recurring_billing_interval interval default '1 month',
```

### New Purchase Tracking

```sql
-- In universal_package_purchases table
purchase_option purchase_option_enum not null default 'one_time',
```

## TypeScript Integration

### Enhanced Types

```typescript
// types/dual-purchase-packages.ts

export type PurchaseOption = "one_time" | "recurring";

export interface DualPurchasePackage {
  id: string;
  name: string;
  description: string;
  package_type: PackageAccessType;

  // Dual purchase support
  supports_one_time_purchase: boolean;
  supports_recurring_purchase: boolean;

  // One-time purchase options
  one_time_price?: number;
  one_time_duration_weeks?: number;

  // Recurring purchase options
  recurring_price?: number;
  recurring_billing_interval?: string; // PostgreSQL interval

  // Credits and features
  appointment_credits: number;
  content_credits: number;
  event_credits: number;
  post_credits: number;

  // Metadata
  currency: string;
  is_active: boolean;
}

export interface PackagePricingOptions {
  one_time?: {
    available: boolean;
    price?: number;
    duration_weeks?: number;
    currency?: string;
  };
  recurring?: {
    available: boolean;
    price?: number;
    billing_interval?: number; // Seconds
    currency?: string;
  };
}

export interface CreateDualPackageParams {
  name: string;
  description?: string;
  package_type?: PackageAccessType;

  // Dual purchase configuration
  supports_one_time_purchase?: boolean;
  supports_recurring_purchase?: boolean;
  one_time_price?: number;
  recurring_price?: number;
  one_time_duration_weeks?: number;
  recurring_billing_interval?: string;

  // Credits and features
  appointment_credits?: number;
  content_credits?: number;
  event_credits?: number;
  post_credits?: number;

  // Other settings
  currency?: string;
  is_active?: boolean;
  requires_approval?: boolean;
}

export interface PurchasePackageParams {
  package_id: string;
  purchase_option: PurchaseOption;
  purchase_id?: string;
  user_id?: string;
}
```

### API Functions

```typescript
// api/packages/dualPurchasePackages.ts

export class DualPurchasePackageAPI {
  // Create package with dual purchase options
  static async createDualPurchasePackage(
    params: CreateDualPackageParams
  ): Promise<{ package_id: string }> {
    const { data, error } = await supabase.rpc("create_universal_package", {
      p_name: params.name,
      p_description: params.description,
      p_package_type: params.package_type || "custom_bundle",

      // Dual purchase options
      p_supports_one_time_purchase: params.supports_one_time_purchase ?? true,
      p_supports_recurring_purchase:
        params.supports_recurring_purchase ?? false,
      p_one_time_price: params.one_time_price,
      p_recurring_price: params.recurring_price,
      p_one_time_duration_weeks: params.one_time_duration_weeks,
      p_recurring_billing_interval: params.recurring_billing_interval,

      // Credits
      p_appointment_credits: params.appointment_credits || 0,
      p_content_credits: params.content_credits || 0,
      p_event_credits: params.event_credits || 0,
      p_post_credits: params.post_credits || 0,

      // Settings
      p_currency: params.currency || "usd",
      p_is_active: params.is_active ?? true,
      p_requires_approval: params.requires_approval ?? false,
    });

    if (error) throw error;
    return data;
  }

  // Purchase package with specific option
  static async purchasePackage(
    params: PurchasePackageParams
  ): Promise<PurchaseUniversalPackageResult> {
    const { data, error } = await supabase.rpc("purchase_universal_package", {
      p_package_id: params.package_id,
      p_purchase_option: params.purchase_option,
      p_purchase_id: params.purchase_id,
      p_user_id: params.user_id,
    });

    if (error) throw error;
    return data;
  }

  // Get pricing options for a package
  static async getPackagePricingOptions(
    packageId: string
  ): Promise<PackagePricingOptions> {
    const { data, error } = await supabase.rpc("get_package_pricing_options", {
      p_package_id: packageId,
    });

    if (error) throw error;
    return data;
  }

  // Get packages with dual purchase support
  static async getDualPurchasePackages(
    creatorId?: string
  ): Promise<DualPurchasePackage[]> {
    let query = supabase
      .from("universal_packages")
      .select(
        `
        *,
        package_access_rules (
          service_id,
          access_type,
          credits_required
        )
      `
      )
      .eq("is_active", true);

    if (creatorId) {
      query = query.eq("creator_id", creatorId);
    }

    const { data, error } = await query;
    if (error) throw error;
    return data || [];
  }
}
```

## Frontend Components

### 1. Package Creation Form with Dual Options

```typescript
// components/packages/CreateDualPackageForm.tsx

const CreateDualPackageForm: React.FC = () => {
  const [formData, setFormData] = useState<CreateDualPackageParams>({
    name: "",
    description: "",
    supports_one_time_purchase: true,
    supports_recurring_purchase: false,
    one_time_price: 0,
    recurring_price: 0,
    one_time_duration_weeks: 4,
    recurring_billing_interval: "1 month",
  });

  const createPackageMutation = useMutation({
    mutationFn: DualPurchasePackageAPI.createDualPurchasePackage,
    onSuccess: (result) => {
      toast.success("Package created with dual purchase options!");
    },
  });

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Basic Info */}
      <section>
        <h3 className="text-lg font-semibold mb-4">Package Details</h3>
        <input
          type="text"
          placeholder="Package Name"
          value={formData.name}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, name: e.target.value }))
          }
          className="form-input"
        />
        <textarea
          placeholder="Description"
          value={formData.description}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, description: e.target.value }))
          }
          className="form-textarea"
        />
      </section>

      {/* Purchase Options */}
      <section className="border-t pt-6">
        <h3 className="text-lg font-semibold mb-4">Purchase Options</h3>

        {/* One-time Purchase Option */}
        <div className="space-y-4 p-4 border rounded-lg">
          <label className="flex items-center space-x-2">
            <input
              type="checkbox"
              checked={formData.supports_one_time_purchase}
              onChange={(e) =>
                setFormData((prev) => ({
                  ...prev,
                  supports_one_time_purchase: e.target.checked,
                }))
              }
              className="form-checkbox"
            />
            <span className="font-medium">Offer One-time Purchase</span>
          </label>

          {formData.supports_one_time_purchase && (
            <div className="grid grid-cols-2 gap-4 ml-6">
              <div>
                <label className="block text-sm font-medium mb-1">
                  One-time Price
                </label>
                <input
                  type="number"
                  step="0.01"
                  min="0"
                  value={formData.one_time_price}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      one_time_price: parseFloat(e.target.value),
                    }))
                  }
                  className="form-input"
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">
                  Duration (weeks)
                </label>
                <input
                  type="number"
                  min="1"
                  value={formData.one_time_duration_weeks}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      one_time_duration_weeks: parseInt(e.target.value),
                    }))
                  }
                  className="form-input"
                  required
                />
              </div>
            </div>
          )}
        </div>

        {/* Recurring Purchase Option */}
        <div className="space-y-4 p-4 border rounded-lg">
          <label className="flex items-center space-x-2">
            <input
              type="checkbox"
              checked={formData.supports_recurring_purchase}
              onChange={(e) =>
                setFormData((prev) => ({
                  ...prev,
                  supports_recurring_purchase: e.target.checked,
                }))
              }
              className="form-checkbox"
            />
            <span className="font-medium">Offer Recurring Subscription</span>
          </label>

          {formData.supports_recurring_purchase && (
            <div className="grid grid-cols-2 gap-4 ml-6">
              <div>
                <label className="block text-sm font-medium mb-1">
                  Monthly Price
                </label>
                <input
                  type="number"
                  step="0.01"
                  min="0"
                  value={formData.recurring_price}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      recurring_price: parseFloat(e.target.value),
                    }))
                  }
                  className="form-input"
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">
                  Billing Interval
                </label>
                <select
                  value={formData.recurring_billing_interval}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      recurring_billing_interval: e.target.value,
                    }))
                  }
                  className="form-select"
                >
                  <option value="1 week">Weekly</option>
                  <option value="1 month">Monthly</option>
                  <option value="3 months">Quarterly</option>
                  <option value="1 year">Yearly</option>
                </select>
              </div>
            </div>
          )}
        </div>

        {/* Validation Message */}
        {!formData.supports_one_time_purchase &&
          !formData.supports_recurring_purchase && (
            <p className="text-red-500 text-sm">
              You must enable at least one purchase option.
            </p>
          )}
      </section>

      {/* Credits Configuration */}
      <section className="border-t pt-6">
        <h3 className="text-lg font-semibold mb-4">Credits & Access</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div>
            <label className="block text-sm font-medium mb-1">
              Appointment Credits
            </label>
            <input
              type="number"
              min="0"
              value={formData.appointment_credits}
              onChange={(e) =>
                setFormData((prev) => ({
                  ...prev,
                  appointment_credits: parseInt(e.target.value),
                }))
              }
              className="form-input"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">
              Content Credits
            </label>
            <input
              type="number"
              min="0"
              value={formData.content_credits}
              onChange={(e) =>
                setFormData((prev) => ({
                  ...prev,
                  content_credits: parseInt(e.target.value),
                }))
              }
              className="form-input"
            />
          </div>
        </div>
      </section>

      <button
        type="submit"
        disabled={createPackageMutation.isPending}
        className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 disabled:opacity-50"
      >
        {createPackageMutation.isPending ? "Creating..." : "Create Package"}
      </button>
    </form>
  );
};
```

### 2. Package Purchase Options Display

```typescript
// components/packages/PackagePurchaseOptions.tsx

interface PackagePurchaseOptionsProps {
  packageId: string;
  onPurchaseSelect: (packageId: string, option: PurchaseOption) => void;
}

const PackagePurchaseOptions: React.FC<PackagePurchaseOptionsProps> = ({
  packageId,
  onPurchaseSelect,
}) => {
  const { data: pricingOptions, isLoading } = useQuery({
    queryKey: ["package-pricing", packageId],
    queryFn: () => DualPurchasePackageAPI.getPackagePricingOptions(packageId),
  });

  if (isLoading) {
    return <div className="animate-pulse">Loading pricing options...</div>;
  }

  if (!pricingOptions) {
    return <div>Pricing information unavailable</div>;
  }

  return (
    <div className="space-y-4">
      <h3 className="text-lg font-semibold">Choose Your Purchase Option</h3>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* One-time Purchase Option */}
        {pricingOptions.one_time?.available && (
          <div className="border rounded-lg p-6 hover:shadow-md transition-shadow">
            <div className="text-center">
              <h4 className="text-xl font-bold mb-2">One-time Purchase</h4>
              <div className="text-3xl font-bold text-blue-600 mb-2">
                ${pricingOptions.one_time.price}
              </div>
              <p className="text-gray-600 mb-4">
                Access for {pricingOptions.one_time.duration_weeks} weeks
              </p>
              <ul className="text-sm text-gray-500 mb-6 space-y-1">
                <li>✓ Pay once, use for full duration</li>
                <li>✓ No recurring charges</li>
                <li>✓ Full access to all features</li>
              </ul>
              <button
                onClick={() => onPurchaseSelect(packageId, "one_time")}
                className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700"
              >
                Purchase One-time
              </button>
            </div>
          </div>
        )}

        {/* Recurring Subscription Option */}
        {pricingOptions.recurring?.available && (
          <div className="border rounded-lg p-6 hover:shadow-md transition-shadow relative">
            {/* Popular badge if both options available */}
            {pricingOptions.one_time?.available && (
              <div className="absolute -top-3 left-1/2 transform -translate-x-1/2">
                <span className="bg-green-500 text-white px-3 py-1 rounded-full text-xs font-medium">
                  Most Popular
                </span>
              </div>
            )}

            <div className="text-center">
              <h4 className="text-xl font-bold mb-2">Monthly Subscription</h4>
              <div className="text-3xl font-bold text-green-600 mb-2">
                ${pricingOptions.recurring.price}
                <span className="text-lg text-gray-500">/month</span>
              </div>
              <p className="text-gray-600 mb-4">
                Continuous access with monthly billing
              </p>
              <ul className="text-sm text-gray-500 mb-6 space-y-1">
                <li>✓ Lower monthly cost</li>
                <li>✓ Cancel anytime</li>
                <li>✓ Always access to latest content</li>
                <li>✓ Automatic renewal</li>
              </ul>
              <button
                onClick={() => onPurchaseSelect(packageId, "recurring")}
                className="w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700"
              >
                Start Subscription
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Comparison Table (if both options available) */}
      {pricingOptions.one_time?.available &&
        pricingOptions.recurring?.available && (
          <div className="mt-8">
            <h4 className="text-lg font-semibold mb-4">Compare Options</h4>
            <div className="overflow-x-auto">
              <table className="w-full border rounded-lg">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-4 py-2 text-left">Feature</th>
                    <th className="px-4 py-2 text-center">One-time</th>
                    <th className="px-4 py-2 text-center">Subscription</th>
                  </tr>
                </thead>
                <tbody>
                  <tr className="border-t">
                    <td className="px-4 py-2">Upfront Cost</td>
                    <td className="px-4 py-2 text-center">
                      ${pricingOptions.one_time.price}
                    </td>
                    <td className="px-4 py-2 text-center">
                      ${pricingOptions.recurring.price}
                    </td>
                  </tr>
                  <tr className="border-t">
                    <td className="px-4 py-2">Recurring Charges</td>
                    <td className="px-4 py-2 text-center">None</td>
                    <td className="px-4 py-2 text-center">Monthly</td>
                  </tr>
                  <tr className="border-t">
                    <td className="px-4 py-2">Duration</td>
                    <td className="px-4 py-2 text-center">
                      {pricingOptions.one_time.duration_weeks} weeks
                    </td>
                    <td className="px-4 py-2 text-center">Until cancelled</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        )}
    </div>
  );
};
```

## Stripe Integration

### Enhanced Webhook Processing

```typescript
// api/stripe/webhook/dual-package-handler.ts

export async function handleDualPackagePurchase(
  stripeEvent: Stripe.Event,
  paymentIntent: Stripe.PaymentIntent
) {
  const metadata = paymentIntent.metadata;

  if (!metadata.package_id || !metadata.purchase_option) {
    throw new Error("Missing package metadata for dual purchase");
  }

  // Process purchase with specific option
  const result = await supabase.rpc("purchase_universal_package", {
    p_package_id: metadata.package_id,
    p_purchase_option: metadata.purchase_option as PurchaseOption,
    p_purchase_id: metadata.purchase_id,
  });

  // Set up recurring billing if subscription
  if (metadata.purchase_option === "recurring") {
    await createStripeSubscription({
      customer_id: paymentIntent.customer as string,
      package_id: metadata.package_id,
      price_id: metadata.price_id,
    });
  }

  return result;
}
```

## Benefits of Dual Purchase Options

### For Creators

1. **Maximize Revenue**: Capture both commitment-minded (one-time) and flexibility-minded (subscription) customers
2. **Predictable Income**: Recurring subscriptions provide steady revenue
3. **Higher Conversions**: Lower-commitment subscription option reduces purchase friction
4. **Customer Insights**: Track which purchase models work best

### For Customers

1. **Payment Flexibility**: Choose payment style that fits their budget/commitment level
2. **Risk Management**: Try subscription first, upgrade to one-time later
3. **Cost Optimization**: Choose most economical option for their usage pattern

This dual purchase system gives you the flexibility of modern SaaS platforms while maintaining the simplicity of one-time purchases for customers who prefer that model!
