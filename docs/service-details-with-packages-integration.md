# Service Details with Universal Packages: Integration Guide

## Overview

The enhanced `getServiceDetails` function now returns **only the universal packages that are associated with the specific service** through the `package_access_rules` table. This ensures you get the relevant packages for each service page.

## Database Functions Available

### 1. `get_service_details(service_slug)` - **Backwards Compatible**

Returns JSONB with service info + associated packages

### 2. `get_service_details_with_packages(service_slug)` - **Structured Return**

Returns typed result with all service details

### 3. `get_service_packages(service_slug)` - **Packages Only**

Returns just the packages for a service (useful for package selection components)

## Enhanced Data Structure

### What You Now Get

```json
{
  "service": {
    "id": "service-uuid",
    "slug": "personal-training",
    "title": "Personal Training Session",
    "description": "One-on-one fitness coaching",
    "price": 75.0,
    "duration": 3600, // seconds
    "type": "consultation",
    "capacity": 1,
    "auto_confirm": false
    // ... other service fields
  },
  "creator": {
    "id": "creator-uuid",
    "name": "John Doe",
    "avatar_url": "https://..."
  },
  "location": {
    "id": "location-uuid",
    "name": "Downtown Gym",
    "address": "123 Main St"
  },
  "packages": [
    // ← NEW: Only packages associated with THIS service
    {
      "id": "package-uuid",
      "name": "Training Package - 8 Sessions",
      "description": "8 personal training sessions",
      "package_type": "appointments_only",
      "currency": "usd",
      "is_featured": true,

      "pricing_options": {
        "one_time": {
          "available": true,
          "price": 480.0,
          "duration_weeks": 8,
          "currency": "usd"
        },
        "recurring": {
          "available": true,
          "price": 180.0,
          "billing_interval": 2592000, // seconds in a month
          "currency": "usd"
        }
      },

      "credits": {
        "appointments": 8,
        "content": 0,
        "events": 0,
        "posts": 0
      },

      "service_access": {
        "access_type": "pay_per_use",
        "credits_required": 1,
        "priority": 0
      }
    }
  ]
}
```

## TypeScript Integration

### Enhanced Types

```typescript
// types/service-details-enhanced.ts

export interface ServiceDetailsWithPackages {
  service: {
    id: string;
    slug: string;
    title: string;
    description: string;
    content: string;
    price: number;
    duration: number; // seconds
    type: "consultation" | "workshop" | "course" | "event";
    capacity?: number;
    current_bookings: number;
    auto_confirm: boolean;
    booking_workflow: string;
    thumbnail_url?: string;
    tags: string[];
    status: "draft" | "published" | "archived";
  };
  creator: {
    id: string;
    name: string;
    avatar_url?: string;
  };
  location?: {
    id: string;
    name: string;
    address: string;
  };
  packages: ServicePackage[]; // Only packages for THIS service
}

export interface ServicePackage {
  id: string;
  name: string;
  description?: string;
  package_type:
    | "appointments_only"
    | "content_credits"
    | "unlimited_content"
    | "hybrid_credits"
    | "full_access"
    | "custom_bundle";
  currency: string;
  is_featured: boolean;

  pricing_options: {
    one_time?: {
      available: boolean;
      price?: number;
      duration_weeks?: number;
      currency?: string;
    };
    recurring?: {
      available: boolean;
      price?: number;
      billing_interval?: number; // seconds
      currency?: string;
    };
  };

  credits: {
    appointments: number;
    content: number;
    events: number;
    posts: number;
  };

  service_access: {
    access_type:
      | "pay_per_use"
      | "unlimited"
      | "monthly_allowance"
      | "weekly_allowance";
    credits_required: number;
    priority: number;
  };
}

export interface ServicePackagesOnly {
  service_id: string;
  packages: ServicePackage[];
}
```

### Updated API Functions

```typescript
// api/services/serviceDetails.ts

import { createClient } from "@/utils/supabase/client";
import {
  ServiceDetailsWithPackages,
  ServicePackagesOnly,
} from "@/types/service-details-enhanced";

/**
 * Get complete service details including associated universal packages
 * This replaces your existing getServiceDetails function
 */
export async function getServiceDetails(serviceSlug: string): Promise<{
  data: ServiceDetailsWithPackages | null;
  error: any;
}> {
  try {
    const supabase = createClient();

    const { data, error } = await supabase.rpc("get_service_details", {
      service_slug: serviceSlug,
    });

    if (error) throw error;

    return {
      data: data as ServiceDetailsWithPackages,
      error: null,
    };
  } catch (error) {
    return { data: null, error };
  }
}

/**
 * Get structured service details (alternative with typed return)
 */
export async function getServiceDetailsTyped(serviceSlug: string): Promise<{
  data: any | null;
  error: any;
}> {
  try {
    const supabase = createClient();

    const { data, error } = await supabase.rpc(
      "get_service_details_with_packages",
      {
        p_service_slug: serviceSlug,
      }
    );

    if (error) throw error;

    return { data, error: null };
  } catch (error) {
    return { data: null, error };
  }
}

/**
 * Get only the packages for a service (useful for package selection components)
 */
export async function getServicePackages(serviceSlug: string): Promise<{
  data: ServicePackagesOnly | null;
  error: any;
}> {
  try {
    const supabase = createClient();

    const { data, error } = await supabase.rpc("get_service_packages", {
      p_service_slug: serviceSlug,
    });

    if (error) throw error;

    return {
      data: data as ServicePackagesOnly,
      error: null,
    };
  } catch (error) {
    return { data: null, error };
  }
}
```

## Frontend Component Examples

### 1. Service Page with Package Options

```typescript
// components/service/ServicePageWithPackages.tsx

interface ServicePageProps {
  serviceSlug: string;
}

const ServicePageWithPackages: React.FC<ServicePageProps> = ({
  serviceSlug,
}) => {
  const {
    data: serviceDetails,
    isLoading,
    error,
  } = useQuery({
    queryKey: ["service-details", serviceSlug],
    queryFn: () => getServiceDetails(serviceSlug),
  });

  if (isLoading) return <ServiceDetailsSkeleton />;
  if (error || !serviceDetails.data) return <ServiceNotFound />;

  const { service, creator, location, packages } = serviceDetails.data;

  return (
    <div className="max-w-4xl mx-auto p-6">
      {/* Service Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-4">{service.title}</h1>
        <p className="text-gray-600 mb-4">{service.description}</p>

        <div className="flex items-center space-x-4 mb-6">
          <img
            src={creator.avatar_url || "/default-avatar.png"}
            alt={creator.name}
            className="w-12 h-12 rounded-full"
          />
          <div>
            <p className="font-medium">{creator.name}</p>
            {location && (
              <p className="text-sm text-gray-500">{location.name}</p>
            )}
          </div>
        </div>

        <div className="bg-gray-50 p-4 rounded-lg">
          <p className="text-sm text-gray-600">Individual Session Price</p>
          <p className="text-2xl font-bold">${service.price}</p>
          <p className="text-sm text-gray-500">
            Duration: {Math.round(service.duration / 60)} minutes
          </p>
        </div>
      </div>

      {/* Package Options - Only shows packages for THIS service */}
      {packages.length > 0 && (
        <div className="mb-8">
          <h2 className="text-2xl font-semibold mb-6">Package Options</h2>
          <p className="text-gray-600 mb-6">
            Save money by purchasing sessions in advance
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {packages.map((pkg) => (
              <PackageCard
                key={pkg.id}
                package={pkg}
                serviceSlug={serviceSlug}
                onPurchaseClick={(packageId, option) =>
                  handlePackagePurchase(packageId, option)
                }
              />
            ))}
          </div>
        </div>
      )}

      {/* Individual Booking Section */}
      <div className="border-t pt-8">
        <h2 className="text-2xl font-semibold mb-4">Book Individual Session</h2>
        <IndividualBookingComponent
          serviceId={service.id}
          price={service.price}
        />
      </div>
    </div>
  );
};
```

### 2. Package Card Component

```typescript
// components/packages/PackageCard.tsx

interface PackageCardProps {
  package: ServicePackage;
  serviceSlug: string;
  onPurchaseClick: (
    packageId: string,
    option: "one_time" | "recurring"
  ) => void;
}

const PackageCard: React.FC<PackageCardProps> = ({
  package: pkg,
  serviceSlug,
  onPurchaseClick,
}) => {
  const hasOneTime = pkg.pricing_options.one_time?.available;
  const hasRecurring = pkg.pricing_options.recurring?.available;
  const hasBothOptions = hasOneTime && hasRecurring;

  return (
    <div
      className={`border rounded-lg p-6 ${
        pkg.is_featured ? "ring-2 ring-blue-500" : ""
      }`}
    >
      {pkg.is_featured && (
        <div className="bg-blue-500 text-white px-3 py-1 rounded-full text-sm font-medium mb-4 inline-block">
          Most Popular
        </div>
      )}

      <h3 className="text-xl font-semibold mb-2">{pkg.name}</h3>
      {pkg.description && (
        <p className="text-gray-600 mb-4">{pkg.description}</p>
      )}

      {/* Credits Information */}
      <div className="mb-6">
        <p className="text-sm font-medium text-gray-700 mb-2">
          What's Included:
        </p>
        <ul className="text-sm text-gray-600 space-y-1">
          {pkg.credits.appointments > 0 && (
            <li>✓ {pkg.credits.appointments} appointment credits</li>
          )}
          {pkg.credits.content > 0 && (
            <li>✓ {pkg.credits.content} content access credits</li>
          )}
          {pkg.credits.events > 0 && (
            <li>✓ {pkg.credits.events} event access credits</li>
          )}
          <li>✓ {pkg.service_access.credits_required} credit(s) per session</li>
        </ul>
      </div>

      {/* Pricing Options */}
      <div className="space-y-4">
        {hasOneTime && (
          <div className="border rounded-lg p-4">
            <div className="flex justify-between items-center mb-2">
              <span className="font-medium">One-time Purchase</span>
              <span className="text-2xl font-bold">
                ${pkg.pricing_options.one_time.price}
              </span>
            </div>
            <p className="text-sm text-gray-500 mb-3">
              Valid for {pkg.pricing_options.one_time.duration_weeks} weeks
            </p>
            <button
              onClick={() => onPurchaseClick(pkg.id, "one_time")}
              className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700"
            >
              Purchase Package
            </button>
          </div>
        )}

        {hasRecurring && (
          <div className="border rounded-lg p-4">
            <div className="flex justify-between items-center mb-2">
              <span className="font-medium">Monthly Subscription</span>
              <span className="text-2xl font-bold">
                ${pkg.pricing_options.recurring.price}
                <span className="text-sm text-gray-500">/month</span>
              </span>
            </div>
            <p className="text-sm text-gray-500 mb-3">
              Continuous access, cancel anytime
            </p>
            <button
              onClick={() => onPurchaseClick(pkg.id, "recurring")}
              className={`w-full py-2 px-4 rounded-md ${
                hasBothOptions
                  ? "bg-green-600 hover:bg-green-700 text-white"
                  : "bg-blue-600 hover:bg-blue-700 text-white"
              }`}
            >
              Start Subscription
            </button>
          </div>
        )}
      </div>

      {/* Comparison hint for dual options */}
      {hasBothOptions && (
        <div className="mt-4 p-3 bg-gray-50 rounded-lg">
          <p className="text-xs text-gray-600">
            💡 Save $
            {(
              pkg.pricing_options.one_time.price -
              pkg.pricing_options.recurring.price * 2
            ).toFixed(2)}
            with one-time purchase vs. 2 months subscription
          </p>
        </div>
      )}
    </div>
  );
};
```

### 3. Custom Hook for Service Details

```typescript
// hooks/useServiceDetails.ts

export const useServiceDetails = (serviceSlug: string) => {
  return useQuery({
    queryKey: ["service-details", serviceSlug],
    queryFn: async () => {
      const result = await getServiceDetails(serviceSlug);
      if (result.error) throw result.error;
      return result.data;
    },
    enabled: !!serviceSlug,
  });
};

export const useServicePackages = (serviceSlug: string) => {
  return useQuery({
    queryKey: ["service-packages", serviceSlug],
    queryFn: async () => {
      const result = await getServicePackages(serviceSlug);
      if (result.error) throw result.error;
      return result.data;
    },
    enabled: !!serviceSlug,
  });
};
```

## Key Benefits

### ✅ **Service-Specific Packages**

- Only shows packages that are actually associated with the service
- No irrelevant packages cluttering the UI

### ✅ **Dual Purchase Options**

- Both one-time and recurring options displayed
- Users can choose their preferred payment method

### ✅ **Rich Package Information**

- Credits breakdown shows what's included
- Access patterns and requirements clearly displayed
- Featured packages highlighted

### ✅ **Backwards Compatibility**

- Your existing `getServiceDetails` function continues to work
- Enhanced with package data seamlessly

### ✅ **Performance Optimized**

- Single database call gets all required data
- Packages sorted by priority and featured status

Now your service pages will display **only the relevant universal packages** for each service, giving users clear options between individual sessions and package deals! 🎯
