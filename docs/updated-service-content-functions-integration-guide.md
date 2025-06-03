# Updated Service Content Functions: Universal Package Integration Guide

## Overview

The `create_service_content_with_details` and `update_service_content_with_details` functions have been enhanced to automatically handle universal package integration. When creating or updating services, you can now specify which universal packages should include access to the service.

## What's New

### Enhanced Function Signatures

#### `create_service_content_with_details`

```sql
-- NEW parameters added:
p_universal_package_ids uuid[] default '{}',           -- Array of package IDs
p_package_credits_required integer default 1,          -- Credits per booking
p_package_access_type access_pattern_enum default 'pay_per_use', -- Access pattern
p_package_priority integer default 0                   -- Rule priority
```

#### `update_service_content_with_details`

```sql
-- NEW parameters added:
p_universal_package_ids uuid[] default null,           -- Array of package IDs
p_package_credits_required integer default null,       -- Credits per booking
p_package_access_type access_pattern_enum default null,-- Access pattern
p_package_priority integer default null,               -- Rule priority
p_replace_package_rules boolean default false          -- Replace vs add rules
```

### Enhanced Return Type

```sql
-- New return type with package information:
service_content_with_packages_result:
  post_id uuid
  service_id uuid
  slug text
  package_rules_created integer  -- NEW: How many package rules were created
  package_ids uuid[]             -- NEW: Which packages now include this service
```

## TypeScript Integration

### Backend Types

```typescript
// types/service-content-packages.ts

export interface ServiceContentWithPackagesResult {
  post_id: string;
  service_id: string;
  slug: string;
  package_rules_created: number;
  package_ids: string[];
}

export interface CreateServiceWithPackagesParams {
  // Original service parameters
  title: string;
  slug: string;
  description: string;
  content: string;
  thumbnail_url: string;
  tags: string[];
  status: "draft" | "published" | "archived";
  location_id: string;
  price: number;
  duration: string; // PostgreSQL interval
  type: "consultation" | "workshop" | "course" | "event";
  booking_workflow?: string;
  auto_confirm?: boolean;
  confirmation_deadline_hours?: number;
  capacity?: number;
  waitlist_enabled?: boolean;
  user_id?: string;

  // NEW: Universal package integration
  universal_package_ids?: string[];
  package_credits_required?: number;
  package_access_type?:
    | "pay_per_use"
    | "unlimited"
    | "monthly_allowance"
    | "weekly_allowance";
  package_priority?: number;
}

export interface UpdateServiceWithPackagesParams
  extends Partial<CreateServiceWithPackagesParams> {
  post_id: string;
  // NEW: Package management options
  replace_package_rules?: boolean; // Whether to replace existing rules or add to them
}

export interface AddServiceToPackagesParams {
  service_id: string;
  package_ids: string[];
  credits_required?: number;
  access_type?:
    | "pay_per_use"
    | "unlimited"
    | "monthly_allowance"
    | "weekly_allowance";
  priority?: number;
}

export interface RemoveServiceFromPackagesParams {
  service_id: string;
  package_ids?: string[]; // If not provided, removes from all packages
}

export interface PackageRuleResult {
  success: boolean;
  service_id: string;
  rules_created?: number;
  rules_removed?: number;
  package_ids: string[];
}
```

### API Functions

```typescript
// api/services/serviceContentWithPackages.ts

export class ServiceContentPackageAPI {
  // Create service with automatic package integration
  static async createServiceWithPackages(
    params: CreateServiceWithPackagesParams
  ): Promise<ServiceContentWithPackagesResult> {
    const { data, error } = await supabase.rpc(
      "create_service_content_with_details",
      {
        p_title: params.title,
        p_slug: params.slug,
        p_description: params.description,
        p_content: params.content,
        p_thumbnail_url: params.thumbnail_url,
        p_tags: params.tags,
        p_status: params.status,
        p_location_id: params.location_id,
        p_price: params.price,
        p_duration: params.duration,
        p_type: params.type,
        p_booking_workflow: params.booking_workflow,
        p_auto_confirm: params.auto_confirm,
        p_confirmation_deadline_hours: params.confirmation_deadline_hours,
        p_capacity: params.capacity,
        p_waitlist_enabled: params.waitlist_enabled,
        user_id: params.user_id,
        // NEW: Universal package parameters
        p_universal_package_ids: params.universal_package_ids || [],
        p_package_credits_required: params.package_credits_required || 1,
        p_package_access_type: params.package_access_type || "pay_per_use",
        p_package_priority: params.package_priority || 0,
      }
    );

    if (error) throw error;
    return data;
  }

  // Update service with package integration
  static async updateServiceWithPackages(
    params: UpdateServiceWithPackagesParams
  ): Promise<ServiceContentWithPackagesResult> {
    const { data, error } = await supabase.rpc(
      "update_service_content_with_details",
      {
        p_post_id: params.post_id,
        p_title: params.title,
        p_slug: params.slug,
        p_description: params.description,
        p_content: params.content,
        p_thumbnail_url: params.thumbnail_url,
        p_tags: params.tags,
        p_status: params.status,
        p_location_id: params.location_id,
        p_price: params.price,
        p_duration: params.duration,
        p_type: params.type,
        p_booking_workflow: params.booking_workflow,
        p_auto_confirm: params.auto_confirm,
        p_confirmation_deadline_hours: params.confirmation_deadline_hours,
        p_capacity: params.capacity,
        p_waitlist_enabled: params.waitlist_enabled,
        // NEW: Universal package parameters
        p_universal_package_ids: params.universal_package_ids,
        p_package_credits_required: params.package_credits_required,
        p_package_access_type: params.package_access_type,
        p_package_priority: params.package_priority,
        p_replace_package_rules: params.replace_package_rules || false,
      }
    );

    if (error) throw error;
    return data;
  }

  // Add existing service to packages
  static async addServiceToPackages(
    params: AddServiceToPackagesParams
  ): Promise<PackageRuleResult> {
    const { data, error } = await supabase.rpc(
      "add_service_to_universal_packages",
      {
        p_service_id: params.service_id,
        p_package_ids: params.package_ids,
        p_credits_required: params.credits_required || 1,
        p_access_type: params.access_type || "pay_per_use",
        p_priority: params.priority || 0,
      }
    );

    if (error) throw error;
    return data;
  }

  // Remove service from packages
  static async removeServiceFromPackages(
    params: RemoveServiceFromPackagesParams
  ): Promise<PackageRuleResult> {
    const { data, error } = await supabase.rpc(
      "remove_service_from_universal_packages",
      {
        p_service_id: params.service_id,
        p_package_ids: params.package_ids,
      }
    );

    if (error) throw error;
    return data;
  }
}
```

## Frontend Integration Examples

### 1. Create Service Form with Package Selection

```typescript
// components/services/CreateServiceWithPackagesForm.tsx

interface CreateServiceFormProps {
  onSuccess: (result: ServiceContentWithPackagesResult) => void;
}

const CreateServiceWithPackagesForm: React.FC<CreateServiceFormProps> = ({
  onSuccess,
}) => {
  const [formData, setFormData] = useState<CreateServiceWithPackagesParams>({
    title: "",
    slug: "",
    description: "",
    content: "",
    thumbnail_url: "",
    tags: [],
    status: "draft",
    location_id: "",
    price: 0,
    duration: "01:00:00",
    type: "consultation",
    // Package integration
    universal_package_ids: [],
    package_credits_required: 1,
    package_access_type: "pay_per_use",
  });

  // Get creator's packages for selection
  const { data: creatorPackages } = useQuery({
    queryKey: ["creator-packages"],
    queryFn: () => getCreatorPackages(),
  });

  const createServiceMutation = useMutation({
    mutationFn: ServiceContentPackageAPI.createServiceWithPackages,
    onSuccess: (result) => {
      toast.success(
        `Service created successfully! Added to ${result.package_rules_created} packages.`
      );
      onSuccess(result);
    },
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await createServiceMutation.mutateAsync(formData);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Standard service fields */}
      <ServiceBasicFields formData={formData} onChange={setFormData} />

      {/* NEW: Package Integration Section */}
      <section className="border-t pt-6">
        <h3 className="text-lg font-semibold mb-4">Package Integration</h3>

        {/* Package Selection */}
        <div className="space-y-4">
          <label className="block text-sm font-medium">
            Include in Packages
            <p className="text-xs text-gray-500 mt-1">
              Select which packages should include access to this service
            </p>
          </label>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
            {creatorPackages?.map((pkg) => (
              <label key={pkg.id} className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  checked={formData.universal_package_ids?.includes(pkg.id)}
                  onChange={(e) => {
                    const newIds = e.target.checked
                      ? [...(formData.universal_package_ids || []), pkg.id]
                      : formData.universal_package_ids?.filter(
                          (id) => id !== pkg.id
                        ) || [];
                    setFormData((prev) => ({
                      ...prev,
                      universal_package_ids: newIds,
                    }));
                  }}
                  className="form-checkbox"
                />
                <span className="text-sm">{pkg.name}</span>
              </label>
            ))}
          </div>

          {/* Package Settings */}
          {formData.universal_package_ids?.length > 0 && (
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 p-4 bg-gray-50 rounded-lg">
              <div>
                <label className="block text-sm font-medium mb-1">
                  Credits Required
                </label>
                <input
                  type="number"
                  min="1"
                  value={formData.package_credits_required}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      package_credits_required: parseInt(e.target.value),
                    }))
                  }
                  className="form-input"
                />
              </div>

              <div>
                <label className="block text-sm font-medium mb-1">
                  Access Type
                </label>
                <select
                  value={formData.package_access_type}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      package_access_type: e.target.value as any,
                    }))
                  }
                  className="form-select"
                >
                  <option value="pay_per_use">Pay Per Use</option>
                  <option value="unlimited">Unlimited</option>
                  <option value="monthly_allowance">Monthly Allowance</option>
                  <option value="weekly_allowance">Weekly Allowance</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium mb-1">
                  Priority
                </label>
                <input
                  type="number"
                  min="0"
                  value={formData.package_priority}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      package_priority: parseInt(e.target.value),
                    }))
                  }
                  className="form-input"
                />
              </div>
            </div>
          )}
        </div>
      </section>

      <button
        type="submit"
        disabled={createServiceMutation.isPending}
        className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 disabled:opacity-50"
      >
        {createServiceMutation.isPending ? "Creating..." : "Create Service"}
      </button>
    </form>
  );
};
```

### 2. Manage Service Package Access

```typescript
// components/services/ServicePackageManager.tsx

interface ServicePackageManagerProps {
  serviceId: string;
  currentPackageIds: string[];
}

const ServicePackageManager: React.FC<ServicePackageManagerProps> = ({
  serviceId,
  currentPackageIds,
}) => {
  const [selectedPackages, setSelectedPackages] =
    useState<string[]>(currentPackageIds);
  const [accessSettings, setAccessSettings] = useState({
    credits_required: 1,
    access_type: "pay_per_use" as const,
    priority: 0,
  });

  const { data: creatorPackages } = useQuery({
    queryKey: ["creator-packages"],
    queryFn: () => getCreatorPackages(),
  });

  const addToPackagesMutation = useMutation({
    mutationFn: ServiceContentPackageAPI.addServiceToPackages,
    onSuccess: (result) => {
      toast.success(`Added to ${result.rules_created} packages`);
    },
  });

  const removeFromPackagesMutation = useMutation({
    mutationFn: ServiceContentPackageAPI.removeServiceFromPackages,
    onSuccess: (result) => {
      toast.success(`Removed from ${result.rules_removed} packages`);
    },
  });

  const handleAddToPackages = async () => {
    const newPackages = selectedPackages.filter(
      (id) => !currentPackageIds.includes(id)
    );
    if (newPackages.length === 0) return;

    await addToPackagesMutation.mutateAsync({
      service_id: serviceId,
      package_ids: newPackages,
      ...accessSettings,
    });
  };

  const handleRemoveFromPackages = async () => {
    const packagesToRemove = currentPackageIds.filter(
      (id) => !selectedPackages.includes(id)
    );
    if (packagesToRemove.length === 0) return;

    await removeFromPackagesMutation.mutateAsync({
      service_id: serviceId,
      package_ids: packagesToRemove,
    });
  };

  return (
    <div className="space-y-6">
      <h3 className="text-lg font-semibold">Manage Package Access</h3>

      {/* Package Selection */}
      <div className="space-y-2">
        <label className="block text-sm font-medium">
          Included in Packages
        </label>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
          {creatorPackages?.map((pkg) => (
            <label key={pkg.id} className="flex items-center space-x-2">
              <input
                type="checkbox"
                checked={selectedPackages.includes(pkg.id)}
                onChange={(e) => {
                  const newSelection = e.target.checked
                    ? [...selectedPackages, pkg.id]
                    : selectedPackages.filter((id) => id !== pkg.id);
                  setSelectedPackages(newSelection);
                }}
                className="form-checkbox"
              />
              <span className="text-sm">{pkg.name}</span>
              {currentPackageIds.includes(pkg.id) && (
                <span className="text-xs text-green-600">
                  (currently included)
                </span>
              )}
            </label>
          ))}
        </div>
      </div>

      {/* Access Settings */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 p-4 bg-gray-50 rounded-lg">
        <div>
          <label className="block text-sm font-medium mb-1">
            Credits Required
          </label>
          <input
            type="number"
            min="1"
            value={accessSettings.credits_required}
            onChange={(e) =>
              setAccessSettings((prev) => ({
                ...prev,
                credits_required: parseInt(e.target.value),
              }))
            }
            className="form-input"
          />
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">Access Type</label>
          <select
            value={accessSettings.access_type}
            onChange={(e) =>
              setAccessSettings((prev) => ({
                ...prev,
                access_type: e.target.value as any,
              }))
            }
            className="form-select"
          >
            <option value="pay_per_use">Pay Per Use</option>
            <option value="unlimited">Unlimited</option>
            <option value="monthly_allowance">Monthly Allowance</option>
            <option value="weekly_allowance">Weekly Allowance</option>
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">Priority</label>
          <input
            type="number"
            min="0"
            value={accessSettings.priority}
            onChange={(e) =>
              setAccessSettings((prev) => ({
                ...prev,
                priority: parseInt(e.target.value),
              }))
            }
            className="form-input"
          />
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex space-x-4">
        <button
          onClick={handleAddToPackages}
          disabled={addToPackagesMutation.isPending}
          className="bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700 disabled:opacity-50"
        >
          {addToPackagesMutation.isPending ? "Adding..." : "Apply Changes"}
        </button>

        <button
          onClick={handleRemoveFromPackages}
          disabled={removeFromPackagesMutation.isPending}
          className="bg-red-600 text-white px-4 py-2 rounded-md hover:bg-red-700 disabled:opacity-50"
        >
          {removeFromPackagesMutation.isPending
            ? "Removing..."
            : "Remove from Packages"}
        </button>
      </div>
    </div>
  );
};
```

## Migration Strategy

### 1. Backward Compatibility

The enhanced functions maintain full backward compatibility. Existing calls work unchanged:

```typescript
// This still works exactly as before
const result = await supabase.rpc("create_service_content_with_details", {
  p_title: "Yoga Class",
  p_slug: "yoga-class",
  // ... other existing parameters
  // NEW parameters are optional with sensible defaults
});
```

### 2. Gradual Migration

```typescript
// Phase 1: Use existing function calls
const service1 = await createServiceContentWithDetails(basicParams);

// Phase 2: Add package integration to new services
const service2 = await createServiceContentWithDetails({
  ...basicParams,
  universal_package_ids: [packageId1, packageId2],
});

// Phase 3: Retrofit existing services
await addServiceToPackages({
  service_id: service1.service_id,
  package_ids: [packageId1],
});
```

### 3. Benefits

1. **Atomic Operations**: Service creation and package access rules are created in a single transaction
2. **Validation**: Automatically validates package ownership and existence
3. **Flexibility**: Supports all access patterns (pay-per-use, unlimited, allowances)
4. **Error Handling**: Graceful handling of invalid packages with warnings
5. **Convenience**: Helper functions for managing existing services

This integration makes it seamless to include services in universal packages right from the service creation workflow, while maintaining full flexibility for complex scenarios.
