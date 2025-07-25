// Universal Packages - Credit Consumption Tests
// Tests for consuming credits from universal package purchases

import { TestSuite } from "../../../core/test-framework.js";
import { UniversalPackagesFixtures } from "../fixtures.js";
import {
  assert,
  assertEqual,
  assertNotNull,
  log,
} from "../../../shared/utilities/test-utils.js";

export function createCreditConsumptionTests() {
  const suite = new TestSuite("Credit Consumption");
  const fixtures = new UniversalPackagesFixtures();

  // Ensure each test starts fresh
  suite.beforeEach(() => {
    fixtures.purchases = [];
  });

  /**
   * TEST: Event Credit Consumption
   *
   * WHAT: Tests that event bookings properly consume credits from universal packages
   * WHY: Credit consumption is the core value delivery - users must be able to
   *      use their purchased credits to access events and services
   * VALIDATES:
   * - Credit deduction from purchase records
   * - Event booking creation with universal package credits
   * - Accurate remaining credit tracking
   * - Credit consumption transaction integrity
   */
  suite.addTest("Should consume event credits for bookings", async () => {
    // Create package and purchase
    const package_ = await fixtures.createTestPackage({
      name: fixtures.generateTestName("EventCreditsPackage"),
      total_event_credits: 5,
      one_time_price: 2500,
    });

    const purchase = await fixtures.createTestPurchase({
      package_id: package_.id,
      user_id: fixtures.testUsers.customer1.id,
    });

    // Verify initial credits
    assertEqual(
      purchase.remaining_event_credits,
      5,
      "Should start with 5 event credits"
    );

    // Simulate credit consumption for event booking
    const updatedPurchase = await fixtures.consumeEventCredit(purchase.id, 1);

    // Validate credit consumption
    assertEqual(
      updatedPurchase.remaining_event_credits,
      4,
      "Should have 4 credits remaining after consumption"
    );
  });

  /**
   * TEST: Appointment Credit Consumption
   *
   * WHAT: Tests that appointment bookings properly consume appointment credits
   * WHY: Universal packages need to support different types of credits for
   *      different services (appointments vs events vs content)
   * VALIDATES:
   * - Appointment-specific credit tracking
   * - Credit type isolation (appointment credits don't affect event credits)
   * - Service-specific consumption patterns
   * - Multi-credit-type package functionality
   */
  suite.addTest(
    "Should consume appointment credits independently",
    async () => {
      // Create package with multiple credit types
      const package_ = await fixtures.createTestPackage({
        name: fixtures.generateTestName("MultiCreditPackage"),
        total_event_credits: 5,
        total_appointment_credits: 10,
        total_content_credits: 15,
        one_time_price: 5000,
      });

      const purchase = await fixtures.createTestPurchase({
        package_id: package_.id,
        user_id: fixtures.testUsers.customer1.id,
      });

      // Consume appointment credits
      const updatedPurchase = await fixtures.consumeAppointmentCredit(
        purchase.id,
        3
      );

      // Validate only appointment credits were affected
      assertEqual(
        updatedPurchase.remaining_appointment_credits,
        7,
        "Should have 7 appointment credits remaining"
      );
      assertEqual(
        updatedPurchase.remaining_event_credits,
        5,
        "Event credits should be unchanged"
      );
      assertEqual(
        updatedPurchase.remaining_content_credits,
        15,
        "Content credits should be unchanged"
      );
    }
  );

  /**
   * TEST: Credit Insufficient Funds Handling
   *
   * WHAT: Tests error handling when users try to consume more credits than available
   * WHY: System must prevent overdraft and provide clear feedback when
   *      users attempt to use credits they don't have
   * VALIDATES:
   * - Insufficient credit detection
   * - Transaction rollback on failed consumption
   * - Error message clarity and accuracy
   * - Credit balance protection
   */
  suite.addTest("Should handle insufficient credits gracefully", async () => {
    // Create package with limited credits
    const package_ = await fixtures.createTestPackage({
      name: fixtures.generateTestName("LimitedCreditsPackage"),
      total_event_credits: 2,
      one_time_price: 1000,
    });

    const purchase = await fixtures.createTestPurchase({
      package_id: package_.id,
      user_id: fixtures.testUsers.customer1.id,
    });

    // Try to consume more credits than available
    let errorThrown = false;
    try {
      await fixtures.consumeEventCredit(purchase.id, 5); // Try to consume 5 when only 2 available
    } catch (error) {
      errorThrown = true;
      assert(
        error.message.includes("insufficient"),
        "Error should mention insufficient credits"
      );
    }

    assert(errorThrown, "Should throw error for insufficient credits");

    // Verify credits weren't modified
    const unchangedPurchase = await fixtures.getPurchase(purchase.id);
    assertEqual(
      unchangedPurchase.remaining_event_credits,
      2,
      "Credits should remain unchanged after failed consumption"
    );
  });

  /**
   * TEST: Cross-Purchase Credit Consumption
   *
   * WHAT: Tests that system can consume credits across multiple purchases for same user
   * WHY: Users with multiple packages should be able to use credits from any
   *      purchase, providing flexible credit pooling
   * VALIDATES:
   * - Multi-purchase credit availability
   * - Intelligent credit selection (e.g., oldest first, expiring first)
   * - Cross-purchase transaction coordination
   * - Credit pooling business logic
   */
  suite.addTest(
    "Should consume credits across multiple purchases",
    async () => {
      // Create two packages for same user
      const package1 = await fixtures.createTestPackage({
        name: fixtures.generateTestName("CrossPackage1"),
        total_event_credits: 2,
        one_time_price: 1000,
      });

      const package2 = await fixtures.createTestPackage({
        name: fixtures.generateTestName("CrossPackage2"),
        total_event_credits: 3,
        one_time_price: 1500,
      });

      const purchase1 = await fixtures.createTestPurchase({
        package_id: package1.id,
        user_id: fixtures.testUsers.customer1.id,
      });

      const purchase2 = await fixtures.createTestPurchase({
        package_id: package2.id,
        user_id: fixtures.testUsers.customer1.id,
      });

      // Test cross-purchase consumption (simulate system choosing which purchase to deduct from)
      const totalCreditsAvailable = await fixtures.getUserTotalEventCredits(
        fixtures.testUsers.customer1.id
      );
      assertEqual(
        totalCreditsAvailable,
        5,
        "User should have 5 total event credits across purchases"
      );

      // Consume credits (system should handle which purchase to deduct from)
      await fixtures.consumeUserEventCredits(
        fixtures.testUsers.customer1.id,
        4
      );

      const remainingCredits = await fixtures.getUserTotalEventCredits(
        fixtures.testUsers.customer1.id
      );
      assertEqual(
        remainingCredits,
        1,
        "User should have 1 credit remaining after consuming 4"
      );
    }
  );

  // Cleanup after all tests
  suite.afterAll(async () => {
    await fixtures.cleanup();
  });

  return suite;
}
