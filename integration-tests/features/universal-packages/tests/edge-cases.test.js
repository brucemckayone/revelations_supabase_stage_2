// Universal Packages - Edge Cases and Error Handling Tests
// Tests for boundary conditions and error scenarios

import { TestSuite } from "../../../core/test-framework.js";
import { UniversalPackagesFixtures } from "../fixtures.js";
import {
  assert,
  assertEqual,
  assertNotNull,
  log,
} from "../../../shared/utilities/test-utils.js";

export function createEdgeCasesTests() {
  const suite = new TestSuite("Edge Cases");
  const fixtures = new UniversalPackagesFixtures();

  /**
   * TEST: Expired Package Purchase Handling
   *
   * WHAT: Tests system behavior when trying to use credits from expired packages
   * WHY: Expired packages should not allow credit consumption - users must
   *      renew or purchase new packages to continue accessing services
   * VALIDATES:
   * - Expiration date enforcement
   * - Credit consumption blocking for expired purchases
   * - Clear error messaging for expired access
   * - System integrity during expiration scenarios
   */
  suite.addTest("Should handle expired package purchases", async () => {
    // Create package with very short duration (simulating expiration)
    const package_ = await fixtures.createTestPackage({
      name: fixtures.generateTestName("ExpiredPackage"),
      total_event_credits: 5,
      one_time_duration_weeks: 1, // Short duration for testing
      one_time_price: 2000,
    });

    const purchase = await fixtures.createTestPurchase({
      package_id: package_.id,
      user_id: fixtures.testUsers.customer1.id,
    });

    // Manually expire the purchase for testing
    await fixtures.expirePurchase(purchase.id);

    // Try to consume credits from expired purchase
    let errorThrown = false;
    try {
      await fixtures.consumeEventCredit(purchase.id, 1);
    } catch (error) {
      errorThrown = true;
      assert(
        error.message.includes("expired") ||
          error.message.includes("unavailable"),
        "Error should mention expiration or unavailability"
      );
    }

    assert(
      errorThrown,
      "Should throw error when trying to use expired credits"
    );
  });

  /**
   * TEST: Invalid Package Configuration Handling
   *
   * WHAT: Tests error handling for packages with invalid or inconsistent configuration
   * WHY: Database constraints and business rules must prevent creation of
   *      packages that would break the system or confuse users
   * VALIDATES:
   * - Package validation rules enforcement
   * - Clear error messages for invalid configurations
   * - Database constraint handling
   * - Business rule validation
   */
  suite.addTest("Should reject invalid package configurations", async () => {
    // Test case 1: Package with no credits and no price
    let errorThrown = false;
    try {
      await fixtures.createTestPackage({
        name: fixtures.generateTestName("InvalidPackage1"),
        total_event_credits: 0,
        total_appointment_credits: 0,
        total_content_credits: 0,
        one_time_price: 0,
      });
    } catch (error) {
      errorThrown = true;
      assert(
        error.message.includes("invalid") || error.message.includes("required"),
        "Should provide meaningful error for invalid configuration"
      );
    }

    assert(errorThrown, "Should reject package with no credits and no price");

    // Test case 2: Package with one-time purchase enabled but missing required fields
    errorThrown = false;
    try {
      await fixtures.createTestPackage({
        name: fixtures.generateTestName("InvalidPackage2"),
        total_event_credits: 5,
        supports_one_time_purchase: true,
        one_time_price: 1000,
        // Missing one_time_duration_weeks - this should fail
        allow_missing_duration: true,
      });
    } catch (error) {
      errorThrown = true;
      assert(
        error.message.includes("duration") ||
          error.message.includes("required"),
        "Should require duration for one-time purchases"
      );
    }

    assert(errorThrown, "Should reject one-time package without duration");
  });

  /**
   * TEST: Concurrent Credit Consumption
   *
   * WHAT: Tests system behavior when multiple processes try to consume credits simultaneously
   * WHY: Race conditions could lead to overselling credits or inconsistent
   *      credit balances in high-traffic scenarios
   * VALIDATES:
   * - Transaction isolation and consistency
   * - Race condition prevention
   * - Accurate credit tracking under concurrency
   * - Database locking mechanisms
   */
  suite.addTest("Should handle concurrent credit consumption", async () => {
    const package_ = await fixtures.createTestPackage({
      name: fixtures.generateTestName("ConcurrencyPackage"),
      total_event_credits: 3, // Limited credits to test contention
      one_time_price: 1500,
    });

    const purchase = await fixtures.createTestPurchase({
      package_id: package_.id,
      user_id: fixtures.testUsers.customer1.id,
    });

    // Simulate concurrent credit consumption attempts
    const consumptionPromises = [
      fixtures.consumeEventCredit(purchase.id, 1),
      fixtures.consumeEventCredit(purchase.id, 1),
      fixtures.consumeEventCredit(purchase.id, 1),
      fixtures.consumeEventCredit(purchase.id, 1), // This should fail - only 3 credits available
    ];

    // Wait for all promises to resolve/reject
    const results = await Promise.allSettled(consumptionPromises);

    // Count successful and failed operations
    const successful = results.filter((r) => r.status === "fulfilled").length;
    const failed = results.filter((r) => r.status === "rejected").length;

    // Should have exactly 3 successful and 1 failed
    assertEqual(
      successful,
      3,
      "Should have exactly 3 successful credit consumptions"
    );
    assertEqual(failed, 1, "Should have exactly 1 failed credit consumption");

    // Verify final credit balance
    const finalPurchase = await fixtures.getPurchase(purchase.id);
    assertEqual(
      finalPurchase.remaining_event_credits,
      0,
      "Should have 0 credits remaining after successful consumptions"
    );
  });

  /**
   * TEST: Non-existent Resource Handling
   *
   * WHAT: Tests error handling when trying to operate on non-existent packages or purchases
   * WHY: System must gracefully handle references to deleted or non-existent
   *      resources without crashing or corrupting data
   * VALIDATES:
   * - Proper 404-style error handling
   * - Resource existence validation
   * - Clean error messages for missing resources
   * - System stability with invalid references
   */
  suite.addTest("Should handle non-existent resources gracefully", async () => {
    const fakePackageId = fixtures.generateUniqueId();
    const fakePurchaseId = fixtures.generateUniqueId();

    // Test non-existent package
    let errorThrown = false;
    try {
      await fixtures.createTestPurchase({
        package_id: fakePackageId,
        user_id: fixtures.testUsers.customer1.id,
      });
    } catch (error) {
      errorThrown = true;
      assert(
        error.message.includes("not found") || error.message.includes("exist"),
        "Should provide clear error for non-existent package"
      );
    }

    assert(errorThrown, "Should reject purchase of non-existent package");

    // Test non-existent purchase
    errorThrown = false;
    try {
      await fixtures.consumeEventCredit(fakePurchaseId, 1);
    } catch (error) {
      errorThrown = true;
      assert(
        error.message.includes("not found") || error.message.includes("exist"),
        "Should provide clear error for non-existent purchase"
      );
    }

    assert(
      errorThrown,
      "Should reject credit consumption on non-existent purchase"
    );
  });

  // Cleanup after all tests
  suite.afterAll(async () => {
    await fixtures.cleanup();
  });

  return suite;
}
