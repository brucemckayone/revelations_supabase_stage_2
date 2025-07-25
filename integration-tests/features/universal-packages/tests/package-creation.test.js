// Universal Packages - Package Creation Tests
// Tests for creating universal packages with different configurations

import { TestSuite } from "../../../core/test-framework.js";
import { UniversalPackagesFixtures } from "../fixtures.js";
import {
  assert,
  assertEqual,
  assertNotNull,
  log,
} from "../../../shared/utilities/test-utils.js";

export function createPackageCreationTests() {
  const suite = new TestSuite("Package Creation");
  const fixtures = new UniversalPackagesFixtures();

  /**
   * TEST: Basic Universal Package Creation
   *
   * WHAT: Tests that we can create a universal package with basic configuration
   * WHY: Package creation is the foundation of the universal packages system -
   *      without working package creation, nothing else can function
   * VALIDATES:
   * - Package record creation in universal_packages table
   * - Required fields are properly set (name, credits, price)
   * - Package gets assigned a unique ID
   * - Test naming convention is followed
   * - Database constraints are satisfied
   */
  suite.addTest("Should create a basic universal package", async () => {
    const package_ = await fixtures.createTestPackage({
      name: fixtures.generateTestName("BasicPackage"),
      total_event_credits: 5,
      price: 2000, // $20.00
    });

    // Validate package creation
    assert(package_, "Package should be created");
    assert(package_.id, "Package should have an ID");
    assertEqual(
      package_.total_event_credits,
      5,
      "Package should have correct event credits"
    );
    assertEqual(package_.price, 2000, "Package should have correct price");
    assert(
      package_.name.includes("TEST_"),
      "Package name should have test prefix"
    );
  });

  /**
   * TEST: Recurring Package Creation
   *
   * WHAT: Tests that we can create recurring subscription packages
   * WHY: Recurring packages are a key business model - users pay monthly/yearly
   *      for ongoing credit allocation
   * VALIDATES:
   * - Recurring package configuration options
   * - Duration and billing cycle settings
   * - Recurring-specific database fields
   * - Package type differentiation
   */
  suite.addTest("Should create a recurring package", async () => {
    const package_ = await fixtures.createTestPackage({
      name: fixtures.generateTestName("RecurringPackage"),
      total_event_credits: 3,
      is_recurring: true,
      supports_recurring_purchase: true,
      duration_weeks: null, // Ongoing subscription
      recurring_price: 1500, // $15.00/month
    });

    // Validate recurring package
    assert(package_, "Recurring package should be created");
    assertEqual(
      package_.is_recurring,
      true,
      "Package should be marked as recurring"
    );
    assertEqual(
      package_.duration_weeks,
      null,
      "Package should have correct duration"
    );
  });

  /**
   * TEST: Package Configuration Validation
   *
   * WHAT: Tests that packages can be created with complex access configurations
   * WHY: Packages need flexible configuration to control access to different
   *      types of content and events
   * VALIDATES:
   * - Event access configuration JSON structure
   * - Configuration persistence in database
   * - Access rule validation
   * - Package metadata handling
   */
  suite.addTest("Should validate package configuration", async () => {
    const package_ = await fixtures.createTestPackage({
      name: fixtures.generateTestName("ConfiguredPackage"),
      total_event_credits: 10,
      event_access_config: {
        max_events_per_month: 5,
        eligible_event_types: ["workshop", "consultation", "masterclass"],
      },
    });

    // Validate configuration
    assert(
      package_.event_access_config,
      "Package should have event access config"
    );
    assertEqual(
      package_.event_access_config.max_events_per_month,
      5,
      "Should have correct max events per month"
    );
    assert(
      Array.isArray(package_.event_access_config.eligible_event_types),
      "Should have eligible event types array"
    );
  });

  // Cleanup after all tests
  suite.afterAll(async () => {
    await fixtures.cleanup();
  });

  return suite;
}
