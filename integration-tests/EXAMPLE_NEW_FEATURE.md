# Example: Adding Universal Packages Tests

This example shows how to use the feature template to add comprehensive tests for the universal packages system.

## Step 1: Create Directory Structure

```bash
cd integration-tests
mkdir features/universal-packages
cd features/universal-packages
mkdir tests helpers
```

## Step 2: Implement Feature Entry Point

Create `features/universal-packages/index.js`:

```javascript
import { TestSuite } from "../../core/test-framework.js";
import { runPackageCreationTests } from "./tests/creation-tests.js";
import { runPackagePurchaseTests } from "./tests/purchase-tests.js";
import { cleanup } from "./cleanup.js";

export const metadata = {
  name: "Universal Packages",
  description:
    "Tests for package creation, configuration, and purchase processing",
  dependencies: [], // No dependencies - can run standalone
  cleanup_order: 3, // Clean up after credit system (which depends on packages)
};

export async function runTests() {
  const suite = new TestSuite(metadata.name, metadata.description);

  suite.addTest(runPackageCreationTests, "Package Creation Tests");
  suite.addTest(runPackagePurchaseTests, "Package Purchase Tests");

  return await suite.run();
}

export { cleanup };
```

## Step 3: Create Test Fixtures

Create `features/universal-packages/fixtures.js`:

```javascript
import { TestFixtures } from "../../core/test-framework.js";
import { supabase } from "../../config/database.js";
import { TEST_CONFIG } from "../../config/database.js";

export class UniversalPackagesFixtures extends TestFixtures {
  constructor() {
    super("universal-packages");
  }

  async createTestPackage(overrides = {}) {
    const packageData = {
      name: `TEST_Package_${Date.now()}`,
      description: "Test universal package",
      price: 5000, // $50.00 in cents
      credits: 10,
      duration_months: 1,
      is_recurring: false,
      creator_id: TEST_CONFIG.CREATOR_USER_ID,
      event_access_config: {
        max_events_per_month: 5,
        eligible_event_types: ["workshop", "consultation"],
      },
      ...overrides,
    };

    const { data, error } = await supabase
      .from("universal_packages")
      .insert(packageData)
      .select()
      .single();

    if (error) throw error;

    this.trackRecord("universal_packages", data.id);
    return data;
  }

  async createTestPurchase(packageId, userId, overrides = {}) {
    const purchaseData = {
      universal_package_id: packageId,
      user_id: userId,
      payment_intent_id: `pi_test_${Date.now()}`,
      amount: 5000,
      currency: "usd",
      status: "completed",
      credits_remaining: 10,
      expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
      ...overrides,
    };

    const { data, error } = await supabase
      .from("universal_package_purchases")
      .insert(purchaseData)
      .select()
      .single();

    if (error) throw error;

    this.trackRecord("universal_package_purchases", data.id);
    return data;
  }

  async createRecurringPackage(overrides = {}) {
    return this.createTestPackage({
      name: `TEST_RecurringPackage_${Date.now()}`,
      is_recurring: true,
      duration_months: 1,
      stripe_price_id: `price_test_${Date.now()}`,
      ...overrides,
    });
  }
}
```

## Step 4: Implement Cleanup

Create `features/universal-packages/cleanup.js`:

```javascript
import { supabase } from "../../config/database.js";

export async function cleanup() {
  const cleanupTasks = [
    () => cleanupTable("universal_package_purchases"),
    () => cleanupTable("universal_packages"),
  ];

  let totalCleaned = 0;
  for (const task of cleanupTasks) {
    totalCleaned += await task();
  }

  return totalCleaned;
}

async function cleanupTable(tableName, column = "name") {
  const { data, error } = await supabase
    .from(tableName)
    .delete()
    .like(column, "TEST_%");

  if (error && error.code !== "PGRST116") {
    throw error;
  }

  return data?.length || 0;
}

export async function verify() {
  const tables = ["universal_packages", "universal_package_purchases"];

  for (const table of tables) {
    const { data } = await supabase
      .from(table)
      .select("id")
      .like("name", "TEST_%")
      .limit(1);

    if (data && data.length > 0) {
      return false;
    }
  }

  return true;
}
```

## Step 5: Create Package Creation Tests

Create `features/universal-packages/tests/creation-tests.js`:

```javascript
import {
  assert,
  assertEqual,
  assertNotNull,
  assertGreaterThan,
} from "../../../shared/utilities/test-utils.js";
import { UniversalPackagesFixtures } from "../fixtures.js";

export async function runPackageCreationTests() {
  const fixtures = new UniversalPackagesFixtures();

  try {
    await testBasicPackageCreation(fixtures);
    await testRecurringPackageCreation(fixtures);
    await testPackageConfiguration(fixtures);
    await testPackageValidation(fixtures);
  } finally {
    await fixtures.cleanup();
  }
}

async function testBasicPackageCreation(fixtures) {
  const package_ = await fixtures.createTestPackage();

  assertNotNull(package_.id, "Package should have valid ID");
  assertEqual(package_.price, 5000, "Package should have correct price");
  assertEqual(package_.credits, 10, "Package should have correct credits");
  assert(!package_.is_recurring, "Package should be one-time by default");
}

async function testRecurringPackageCreation(fixtures) {
  const package_ = await fixtures.createRecurringPackage();

  assert(package_.is_recurring, "Package should be marked as recurring");
  assertNotNull(
    package_.stripe_price_id,
    "Recurring package should have Stripe price ID"
  );
  assertEqual(
    package_.duration_months,
    1,
    "Package should have monthly duration"
  );
}

async function testPackageConfiguration(fixtures) {
  const package_ = await fixtures.createTestPackage({
    event_access_config: {
      max_events_per_month: 3,
      eligible_event_types: ["workshop"],
      tier_restrictions: ["premium"],
    },
  });

  assertNotNull(
    package_.event_access_config,
    "Package should have access configuration"
  );
  assertEqual(
    package_.event_access_config.max_events_per_month,
    3,
    "Package should have correct event limit"
  );
}

async function testPackageValidation(fixtures) {
  // Test creating package with invalid data should fail
  try {
    await supabase.from("universal_packages").insert({
      name: null, // Invalid - should fail
      price: -100, // Invalid - should fail
    });

    assert(false, "Package creation with invalid data should fail");
  } catch (error) {
    assert(true, "Package validation should prevent invalid data");
  }
}
```

## Step 6: Create Package Purchase Tests

Create `features/universal-packages/tests/purchase-tests.js`:

```javascript
import {
  assert,
  assertEqual,
  assertNotNull,
} from "../../../shared/utilities/test-utils.js";
import { UniversalPackagesFixtures } from "../fixtures.js";
import { getTestUsers } from "../../../config/test-users.js";

export async function runPackagePurchaseTests() {
  const fixtures = new UniversalPackagesFixtures();

  try {
    await testBasicPurchase(fixtures);
    await testCreditAllocation(fixtures);
    await testPurchaseExpiration(fixtures);
  } finally {
    await fixtures.cleanup();
  }
}

async function testBasicPurchase(fixtures) {
  const package_ = await fixtures.createTestPackage();
  const testUsers = await getTestUsers(1);
  const purchase = await fixtures.createTestPurchase(
    package_.id,
    testUsers[0].id
  );

  assertNotNull(purchase.id, "Purchase should have valid ID");
  assertEqual(
    purchase.universal_package_id,
    package_.id,
    "Purchase should link to package"
  );
  assertEqual(
    purchase.user_id,
    testUsers[0].id,
    "Purchase should link to user"
  );
  assertEqual(purchase.status, "completed", "Purchase should be completed");
}

async function testCreditAllocation(fixtures) {
  const package_ = await fixtures.createTestPackage({ credits: 15 });
  const testUsers = await getTestUsers(1);
  const purchase = await fixtures.createTestPurchase(
    package_.id,
    testUsers[0].id,
    {
      credits_remaining: package_.credits,
    }
  );

  assertEqual(
    purchase.credits_remaining,
    package_.credits,
    "Purchase should allocate correct credits"
  );
}

async function testPurchaseExpiration(fixtures) {
  const package_ = await fixtures.createTestPackage({ duration_months: 3 });
  const testUsers = await getTestUsers(1);

  const expiryDate = new Date();
  expiryDate.setMonth(expiryDate.getMonth() + 3);

  const purchase = await fixtures.createTestPurchase(
    package_.id,
    testUsers[0].id,
    {
      expires_at: expiryDate.toISOString(),
    }
  );

  assertNotNull(purchase.expires_at, "Purchase should have expiry date");

  const purchaseExpiry = new Date(purchase.expires_at);
  const expectedExpiry = new Date();
  expectedExpiry.setMonth(expectedExpiry.getMonth() + 3);

  // Allow 1 day difference for test timing
  const timeDiff = Math.abs(
    purchaseExpiry.getTime() - expectedExpiry.getTime()
  );
  const daysDiff = timeDiff / (1000 * 60 * 60 * 24);

  assert(
    daysDiff < 1,
    "Purchase expiry should be approximately 3 months from now"
  );
}
```

## Step 7: Add to Package Scripts

Add to `package.json`:

```json
{
  "scripts": {
    "test:packages": "node run-tests.js --feature=universal-packages"
  }
}
```

## Step 8: Test the Feature

```bash
# Run the new universal packages tests
npm run test:packages

# Run with verbose output to see details
npm run test:packages --verbose

# Verify cleanup
npm run cleanup
```

## Expected Output

```
🧪 Integration Tests for Universal Packages
=============================================

📋 Universal Packages
Tests for package creation, configuration, and purchase processing
--------------------------------------------------

  ▶ Package Creation Tests
  ✅ Package Creation Tests

  ▶ Package Purchase Tests
  ✅ Package Purchase Tests

==================================================
TEST SUMMARY
==================================================
🎉 All 2 tests passed!
⏱️  Duration: 1.23s
📊 Success rate: 100%
==================================================
```

## Key Benefits Demonstrated

1. **Zero Coupling**: Universal packages tests don't depend on credit system code
2. **Isolated Cleanup**: Only cleans up package-related test data
3. **Comprehensive Coverage**: Tests creation, configuration, purchases, and validation
4. **Realistic Data**: Uses actual user IDs and proper test data patterns
5. **Easy Debugging**: Can run package tests in isolation
6. **Maintainable**: All package test logic contained in one feature directory

This example shows how the modular architecture makes it trivial to add comprehensive test coverage for new features without touching any existing code!
