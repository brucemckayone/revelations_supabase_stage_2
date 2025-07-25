# New Feature Test Template

Use this template when creating a new feature test module.

## 1. Create Directory Structure

```bash
mkdir features/your-feature-name
cd features/your-feature-name
mkdir tests helpers
```

## 2. Feature Entry Point (`index.js`)

```javascript
import { TestSuite } from "../../core/test-framework.js";
import { runYourMainTests } from "./tests/main-tests.js";
import { cleanup } from "./cleanup.js";

export const metadata = {
  name: "Your Feature Name",
  description: "Brief description of what this feature tests",
  dependencies: [], // e.g., ['credit-system'] if you depend on credit tests
  cleanup_order: 1, // Higher numbers cleaned first (1-10 range)
};

export async function runTests() {
  const suite = new TestSuite(metadata.name, metadata.description);

  // Add your test modules here
  suite.addTest(runYourMainTests, "Main functionality tests");
  // suite.addTest(runYourEdgeCaseTests, 'Edge case tests');

  return await suite.run();
}

export { cleanup };
```

## 3. Test Fixtures (`fixtures.js`)

```javascript
import { TestFixtures } from "../../core/test-framework.js";
import { supabase } from "../../config/database.js";

export class YourFeatureFixtures extends TestFixtures {
  constructor() {
    super("your-feature-name");
  }

  async createTestRecord(overrides = {}) {
    const recordData = {
      // Use TEST_ prefix for all test data
      name: `TEST_YourRecord_${Date.now()}`,
      description: "Test record for your feature",
      // Add your specific fields
      ...overrides,
    };

    const { data, error } = await supabase
      .from("your_table")
      .insert(recordData)
      .select()
      .single();

    if (error) throw error;

    // Track for cleanup
    this.trackRecord("your_table", data.id);
    return data;
  }

  // Add more fixture methods as needed
  async createRelatedTestRecord(parentId, overrides = {}) {
    // Create related test data
  }
}
```

## 4. Cleanup Logic (`cleanup.js`)

```javascript
import { supabase } from "../../config/database.js";

export async function cleanup() {
  // Clean up in reverse dependency order
  const cleanupTasks = [
    () => cleanupTable("child_table"),
    () => cleanupTable("parent_table"),
    () => cleanupTable("your_main_table"),
  ];

  let totalCleaned = 0;
  for (const task of cleanupTasks) {
    try {
      totalCleaned += await task();
    } catch (error) {
      console.error(`Cleanup task failed: ${error.message}`);
    }
  }

  return totalCleaned;
}

async function cleanupTable(tableName, column = "name") {
  const { data, error } = await supabase
    .from(tableName)
    .delete()
    .like(column, "TEST_%");

  if (error && error.code !== "PGRST116") {
    // Ignore "no rows found"
    throw error;
  }

  return data?.length || 0;
}

export async function verify() {
  // Verify no test data remains
  const tables = ["your_main_table", "related_table"];

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

## 5. Main Tests (`tests/main-tests.js`)

```javascript
import {
  assert,
  assertEqual,
  assertNotNull,
  callFunction,
} from "../../../shared/utilities/test-utils.js";
import { YourFeatureFixtures } from "../fixtures.js";
import { getTestUsers } from "../../../config/test-users.js";

export async function runYourMainTests() {
  const fixtures = new YourFeatureFixtures();

  try {
    // Test 1: Basic functionality
    await testBasicFunctionality(fixtures);

    // Test 2: Error handling
    await testErrorHandling(fixtures);

    // Test 3: Edge cases
    await testEdgeCases(fixtures);
  } finally {
    // Always cleanup
    await fixtures.cleanup();
  }
}

async function testBasicFunctionality(fixtures) {
  // Create test data
  const testRecord = await fixtures.createTestRecord();
  const testUsers = await getTestUsers(1);

  // Test your database function
  const { data, error } = await callFunction("your_database_function", {
    p_record_id: testRecord.id,
    p_user_id: testUsers[0].id,
    p_other_param: "test_value",
  });

  // Assertions
  assert(!error, "Function should execute without error");
  assertNotNull(data, "Function should return data");
  assertEqual(data.status, "success", "Function should return success status");
}

async function testErrorHandling(fixtures) {
  // Test with invalid data
  const { data, error } = await callFunction("your_database_function", {
    p_record_id: "invalid-id",
    p_user_id: "invalid-user",
    p_other_param: null,
  });

  assert(error !== null, "Function should return error for invalid input");
  assert(data === null, "Function should not return data on error");
}

async function testEdgeCases(fixtures) {
  // Test boundary conditions, null values, etc.
}
```

## 6. Add to Package.json

Add your feature to the test scripts:

```json
{
  "scripts": {
    "test:your-feature": "node run-tests.js --feature=your-feature-name"
  }
}
```

## 7. Test Your Feature

```bash
# Run your specific feature tests
npm run test:your-feature

# Run with verbose output
npm run test:your-feature --verbose

# Clean up after testing
npm run cleanup
```

## Checklist

- [ ] Created proper directory structure
- [ ] Implemented feature metadata with dependencies
- [ ] Created fixtures with proper `TEST_` prefixed data
- [ ] Implemented cleanup with verification
- [ ] Added comprehensive test scenarios
- [ ] Added script to package.json
- [ ] Tested feature in isolation
- [ ] Verified cleanup works correctly
- [ ] Tested with other features (if dependencies exist)

## Tips

1. **Keep tests focused**: Each test should verify one specific behavior
2. **Use descriptive names**: Test and assertion messages should be clear
3. **Test error paths**: Don't just test success scenarios
4. **Verify cleanup**: Always check that your cleanup actually works
5. **Use realistic data**: Create test data that matches real usage patterns
6. **Document dependencies**: If your feature depends on others, document it clearly

This template ensures your feature tests follow the established patterns and integrate seamlessly with the existing test suite.
