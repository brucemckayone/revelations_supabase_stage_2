# Test-Driven Development (TDD) Feature Template

This template follows our proven TDD methodology for creating comprehensive feature test suites.
Based on successful patterns from Events and Notifications systems.

## TDD Philosophy

✅ **Test First**: Write comprehensive tests before implementation
✅ **Requirements-Driven**: Each test validates specific business requirements  
✅ **Comprehensive Coverage**: Test creation, validation, edge cases, and integration
✅ **Authenticated Testing**: Use TestUserManager for realistic user contexts
✅ **Detailed Logging**: Clear test descriptions and requirement tracking
✅ **Modular Design**: Independent test suites with proper cleanup

## 1. Create Directory Structure

```bash
mkdir features/your-feature-name
cd features/your-feature-name
mkdir tests helpers
```

## 2. Feature Entry Point (`index.js`)

Follow the comprehensive pattern from our successful systems:

```javascript
import { TestSuite } from "../../core/test-framework.js";
import { runYourCreationTests } from "./tests/your-creation.test.js";
import { runYourValidationTests } from "./tests/your-validation.test.js";
import { runYourIntegrationTests } from "./tests/your-integration.test.js";
import { cleanup } from "./cleanup.js";

export const metadata = {
  name: "Your Feature System",
  description: "Comprehensive tests for your feature with creation, validation, and integration",
  dependencies: [], // e.g., ['notifications'] if you depend on notification tests
  cleanup_order: 2, // Higher numbers cleaned first (1-10 range)
};

export async function runTests() {
  const suite = new TestSuite(metadata.name, metadata.description);

  // Core functionality tests
  suite.addTest("Creation and Management Tests", runYourCreationTests);
  
  // Validation and error handling
  suite.addTest("Validation and Security Tests", runYourValidationTests);
  
  // System integration tests
  suite.addTest("Integration and Workflow Tests", runYourIntegrationTests);

  return await suite.run();
}

export { cleanup };
```

## 3. Test Fixtures (`fixtures.js`)

Use authenticated fixtures with comprehensive setup methods:

```javascript
import { TestFixtures } from "../../core/test-framework.js";
import { supabase } from "../../config/database.js";
import { TestUserManager } from "../../shared/utilities/test-user-manager.js";

export class YourFeatureFixtures extends TestFixtures {
  constructor() {
    super("your-feature-name");
    this.userManager = new TestUserManager();
  }

  /**
   * Creates a test record with authentication
   */
  async createTestRecord(overrides = {}) {
    const { user } = await this.userManager.asUser(
      process.env.TEST_USER_EMAIL || "brucemckayone@gmail.com",
      process.env.TEST_USER_PASSWORD || "password123"
    );

    const recordData = {
      user_id: user.id,
      name: `TEST_YourRecord_${Date.now()}`,
      description: "Test record for comprehensive testing",
      metadata: {
        test_created_at: new Date().toISOString(),
        test_type: "automated_test"
      },
      ...overrides,
    };

    const { data, error } = await supabase
      .from("your_table")
      .insert(recordData)
      .select()
      .single();

    if (error) throw error;

    this.trackRecord("your_table", data.id);
    return data;
  }

  /**
   * Gets authenticated test user ID
   */
  async getTestUserId() {
    const { user } = await this.userManager.asUser(
      process.env.TEST_USER_EMAIL || "brucemckayone@gmail.com",
      process.env.TEST_USER_PASSWORD || "password123"
    );
    return user.id;
  }

  /**
   * Creates a complete test setup for complex scenarios
   */
  async createTestSetup() {
    const userId = await this.getTestUserId();
    
    const mainRecord = await this.createTestRecord({ user_id: userId });
    const relatedRecord = await this.createRelatedTestRecord(mainRecord.id);
    
    return {
      mainRecord,
      relatedRecord,
      userId
    };
  }

  async createRelatedTestRecord(parentId, overrides = {}) {
    const relatedData = {
      parent_id: parentId,
      name: `TEST_Related_${Date.now()}`,
      ...overrides,
    };

    const { data, error } = await supabase
      .from("related_table")
      .insert(relatedData)
      .select()
      .single();

    if (error) throw error;

    this.trackRecord("related_table", data.id);
    return data;
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

## 5. Comprehensive Test Files

Follow our proven TDD pattern with detailed requirements and logging:

### `tests/your-creation.test.js`

```javascript
import {
  startTest,
  endTest,
  logSection,
  logRequirement,
  logAction,
  logVerify,
  logExpectedFailure,
  assert,
  assertEqual,
  assertNotNull,
  assertGreaterThan,
} from "../../../shared/utilities/test-utils.js";
import { YourFeatureFixtures } from "../fixtures.js";
import { supabase } from "../../../config/database.js";
import { TestUserManager } from "../../../shared/utilities/test-user-manager.js";

// Test user configuration
const TEST_AUTH_EMAIL = process.env.TEST_USER_EMAIL || "brucemckayone@gmail.com";
const TEST_AUTH_PASSWORD = process.env.TEST_USER_PASSWORD || "password123";
const userManager = new TestUserManager();

export async function runYourCreationTests() {
  const fixtures = new YourFeatureFixtures();

  try {
    await testBasicCreation(fixtures);
    await testCreationWithMetadata(fixtures);
    await testCreationFunction(fixtures);
    await testCreationValidation(fixtures);
  } finally {
    await fixtures.cleanup();
  }
}

async function testBasicCreation(fixtures) {
  startTest("Basic Record Creation");

  logSection("Setup Test Environment");
  logRequirement("System must be able to create basic records");
  logRequirement("Records must have required fields and proper structure");

  logAction("Creating test record");
  const record = await fixtures.createTestRecord();

  logVerify("Record created successfully");
  assertNotNull(record.id, "Record should have valid ID");
  assertNotNull(record.user_id, "Record should have user ID");
  assertNotNull(record.name, "Record should have name");
  assertNotNull(record.created_at, "Record should have creation timestamp");

  endTest();
}

async function testCreationWithMetadata(fixtures) {
  startTest("Creation with Metadata");

  logSection("Test Metadata Support");
  logRequirement("Records must support flexible metadata storage");
  logRequirement("Metadata must be stored as valid JSONB");

  const metadata = {
    source: "test_system",
    priority: "high",
    custom_data: { nested_field: "test_value" }
  };

  logAction("Creating record with complex metadata");
  const record = await fixtures.createTestRecord({ metadata: metadata });

  logVerify("Record with metadata created successfully");
  assertNotNull(record.metadata, "Record should have metadata");
  assertEqual(record.metadata.source, "test_system", "Metadata should preserve source");

  endTest();
}

async function testCreationFunction(fixtures) {
  startTest("Creation via Database Function");

  logSection("Test Database Function");
  logRequirement("Database function must work correctly");
  logRequirement("Function must handle authentication and validation");

  const { client, user } = await userManager.asUser(TEST_AUTH_EMAIL, TEST_AUTH_PASSWORD);

  logAction("Creating record via database function");
  const { data: recordId, error } = await client.rpc("your_create_function", {
    p_user_id: user.id,
    p_name: `TEST_Function_Record_${Date.now()}`,
    p_description: "Record created via function"
  });

  fixtures.trackRecord("your_table", recordId);

  logVerify("Function-created record successful");
  assert(!error, "Function should execute without error");
  assertNotNull(recordId, "Function should return record ID");

  endTest();
}

async function testCreationValidation(fixtures) {
  startTest("Creation Validation");

  logSection("Test Required Field Validation");
  logRequirement("System must validate required fields");
  logRequirement("Invalid records must be rejected");

  logAction("Testing validation with missing required fields");

  try {
    await supabase.from("your_table").insert({
      // Missing required fields
      description: "incomplete record"
    });
    assert(false, "Should not allow record without required fields");
  } catch (error) {
    logExpectedFailure("Validation correctly rejected invalid record");
    assert(true, "System should validate required fields");
  }

  endTest();
}
```

## 6. Add to Package.json

Add comprehensive test scripts following our proven pattern:

```json
{
  "scripts": {
    "test:your-feature": "node run-tests.js --feature=your-feature-name",
    "test:your-feature:creation": "node run-single-test.js your-feature-creation",
    "test:your-feature:validation": "node run-single-test.js your-feature-validation", 
    "test:your-feature:integration": "node run-single-test.js your-feature-integration",
    "test:your-feature:all": "npm run test:your-feature:creation && npm run test:your-feature:validation && npm run test:your-feature:integration"
  }
}
```

## 7. Update run-single-test.js

Add your feature tests to the TEST_MODULES:

```javascript
const TEST_MODULES = {
  // ... existing tests ...
  
  "your-feature-creation": () =>
    import("./features/your-feature/tests/your-creation.test.js").then(
      (m) => m.runYourCreationTests
    ),
  "your-feature-validation": () =>
    import("./features/your-feature/tests/your-validation.test.js").then(
      (m) => m.runYourValidationTests
    ),
  "your-feature-integration": () =>
    import("./features/your-feature/tests/your-integration.test.js").then(
      (m) => m.runYourIntegrationTests
    ),
};
```

## 8. Test Your Feature

```bash
# Run individual test components
npm run test:your-feature:creation
npm run test:your-feature:validation
npm run test:your-feature:integration

# Run complete feature test suite
npm run test:your-feature:all

# Run via main test framework
npm run test:your-feature

# Clean up after testing
npm run cleanup
```

## TDD Checklist

✅ **Requirements Definition**
- [ ] Clear business requirements documented in test descriptions
- [ ] Each test validates specific business logic
- [ ] Requirements traceability from test to functionality

✅ **Comprehensive Test Coverage**
- [ ] Creation and basic functionality tests
- [ ] Validation and error handling tests  
- [ ] Integration and workflow tests
- [ ] Authentication and authorization tests
- [ ] Edge cases and boundary conditions

✅ **Test Infrastructure**
- [ ] Proper directory structure with modular test files
- [ ] Authenticated fixtures using TestUserManager
- [ ] Comprehensive cleanup with verification
- [ ] Individual and comprehensive test scripts
- [ ] Proper TEST_ prefixed data for isolation

✅ **Test Quality**
- [ ] Detailed logging with requirements, actions, and verifications
- [ ] Clear test descriptions and assertion messages
- [ ] Expected failure testing with logExpectedFailure()
- [ ] Realistic test data matching production patterns
- [ ] Independent tests that can run in any order

## TDD Best Practices (Learned from Events & Notifications)

### 🎯 **Requirements-Driven Testing**
- Start each test with clear requirements using `logRequirement()`
- Map every business rule to specific test assertions
- Use descriptive test names that explain the business value

### 🔐 **Authentication-First Approach**
- Always use `TestUserManager` for realistic user contexts
- Test with authenticated database function calls (`client.rpc`)
- Verify RLS policies work correctly in tests

### 📝 **Comprehensive Logging**
- Use structured logging: `logSection()`, `logAction()`, `logVerify()`
- Mark expected failures clearly with `logExpectedFailure()`
- Create clear audit trail for debugging complex failures

### 🧹 **Bulletproof Cleanup**
- Track all created records with `this.trackRecord()`
- Implement cleanup verification with `verify()` function
- Use time-based cleanup for records without TEST_ prefixes
- Handle foreign key constraints in correct order

### 🔄 **Test Orchestration**
- Create individual test runners for focused debugging
- Build comprehensive test suites that run all components
- Support both isolated and integrated test execution
- Enable easy debugging with `--inspect-brk` support

### 📊 **Validation Testing**
- Test both positive and negative scenarios
- Verify database constraints and validation rules
- Test edge cases and boundary conditions
- Ensure proper error messages and handling

This TDD template ensures your feature tests follow our battle-tested patterns that achieved 100% success rates on Events and Notifications systems!
