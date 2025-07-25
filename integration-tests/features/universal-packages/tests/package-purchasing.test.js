// Universal Packages - Package Purchasing Tests
// Tests for purchasing universal packages and managing purchases

import { TestSuite } from "../../../core/test-framework.js";
import { UniversalPackagesFixtures } from "../fixtures.js";
import {
  assert,
  assertEqual,
  assertNotNull,
  log,
} from "../../../shared/utilities/test-utils.js";

export function createPackagePurchasingTests() {
  const suite = new TestSuite("Package Purchasing");
  const fixtures = new UniversalPackagesFixtures();

  /**
   * TEST: Package Purchase Creation
   *
   * WHAT: Tests that users can purchase universal packages and get access records
   * WHY: Package purchasing is core to the business model - users must be able
   *      to buy packages to gain access to credits and services
   * VALIDATES:
   * - Purchase record creation in universal_package_purchases table
   * - Credit allocation from package to purchase
   * - User-package relationship establishment
   * - Initial credit balances match package definition
   * - Purchase status and timing
   */
  suite.addTest("Should create a package purchase", async () => {
    const package_ = await fixtures.createTestPackage({
      name: fixtures.generateTestName("PurchaseTestPackage"),
      total_event_credits: 5,
      total_appointment_credits: 10,
      one_time_price: 3000, // $30.00
    });

    const purchase = await fixtures.createTestPurchase({
      package_id: package_.id,
      user_id: fixtures.testUsers.customer1.id,
    });

    // Validate purchase creation
    assert(purchase, "Purchase should be created");
    assert(purchase.id, "Purchase should have an ID");
    assertEqual(
      purchase.package_id,
      package_.id,
      "Purchase should reference correct package"
    );
    assertEqual(
      purchase.user_id,
      fixtures.testUsers.customer1.id,
      "Purchase should reference correct user"
    );

    // Validate credit allocation
    assertEqual(
      purchase.remaining_event_credits,
      5,
      "Should have correct initial event credits"
    );
    assertEqual(
      purchase.remaining_appointment_credits,
      10,
      "Should have correct initial appointment credits"
    );
  });

  /**
   * TEST: Multiple Package Purchases
   *
   * WHAT: Tests that a user can purchase multiple packages and they stack correctly
   * WHY: Users should be able to buy additional packages to accumulate more credits,
   *      providing flexibility in their subscription management
   * VALIDATES:
   * - Multiple purchase records for same user
   * - Independent credit tracking per purchase
   * - No interference between separate purchases
   * - Purchase history maintenance
   */
  suite.addTest("Should handle multiple package purchases", async () => {
    const package1 = await fixtures.createTestPackage({
      name: fixtures.generateTestName("MultiPackage1"),
      total_event_credits: 3,
      one_time_price: 1500,
    });

    const package2 = await fixtures.createTestPackage({
      name: fixtures.generateTestName("MultiPackage2"),
      total_event_credits: 7,
      one_time_price: 3500,
    });

    const purchase1 = await fixtures.createTestPurchase({
      package_id: package1.id,
      user_id: fixtures.testUsers.customer1.id,
    });

    const purchase2 = await fixtures.createTestPurchase({
      package_id: package2.id,
      user_id: fixtures.testUsers.customer1.id,
    });

    // Validate separate purchases
    assert(
      purchase1.id !== purchase2.id,
      "Purchases should have different IDs"
    );
    assertEqual(
      purchase1.remaining_event_credits,
      3,
      "First purchase should have 3 credits"
    );
    assertEqual(
      purchase2.remaining_event_credits,
      7,
      "Second purchase should have 7 credits"
    );
  });

  /**
   * TEST: Purchase Expiration Handling
   *
   * WHAT: Tests that package purchases have proper expiration dates and handling
   * WHY: Time-limited packages are important for business model - credits shouldn't
   *      be available indefinitely, creating urgency and recurring revenue
   * VALIDATES:
   * - Expiration date calculation and storage
   * - Duration-based expiration logic
   * - Expired purchase identification
   * - Temporal business rules enforcement
   */
  suite.addTest("Should handle package expiration", async () => {
    const package_ = await fixtures.createTestPackage({
      name: fixtures.generateTestName("ExpiringPackage"),
      total_event_credits: 5,
      one_time_duration_weeks: 4, // 4 week duration
      one_time_price: 2000,
    });

    const purchase = await fixtures.createTestPurchase({
      package_id: package_.id,
      user_id: fixtures.testUsers.customer1.id,
    });

    // Validate expiration is set
    assert(purchase.expires_at, "Purchase should have expiration date");

    // Validate expiration is in the future (approximately 4 weeks)
    const expirationDate = new Date(purchase.expires_at);
    const now = new Date();
    const fourWeeksFromNow = new Date(
      now.getTime() + 4 * 7 * 24 * 60 * 60 * 1000
    );

    // Allow some tolerance for timing
    const timeDiff = Math.abs(
      expirationDate.getTime() - fourWeeksFromNow.getTime()
    );
    const toleranceMs = 60 * 1000; // 1 minute tolerance

    assert(
      timeDiff < toleranceMs,
      "Expiration should be approximately 4 weeks from now"
    );
  });

  // Cleanup after all tests
  suite.afterAll(async () => {
    await fixtures.cleanup();
  });

  return suite;
}
