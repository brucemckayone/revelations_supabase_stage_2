// Subscription Billing Feature - Main Tests

import { TestSuite } from "../../../core/test-framework.js";
import { SubscriptionBillingFixtures } from "../fixtures.js";
import {
  assert,
  assertEqual,
  assertNotNull,
  callFunction,
  log,
} from "../../../shared/utilities/test-utils.js";

/**
 * Run all subscription billing tests
 * @returns {Promise<Object>} Test results
 */
export async function runSubscriptionTests() {
  const suite = new TestSuite(
    "Subscription Billing",
    "Tests subscription billing cycles and credit refresh"
  );

  // Test setup - create fixtures instance
  let fixtures = null;

  suite.beforeAll(async () => {
    fixtures = new SubscriptionBillingFixtures();
    log("Subscription billing test setup complete", "debug");
  });

  suite.afterAll(async () => {
    if (fixtures) {
      await fixtures.cleanup();
      log("Subscription billing test cleanup complete", "debug");
    }
  });

  // Subscription Creation Tests
  suite.addTest("Should create a subscription scenario", async () => {
    const scenario = await fixtures.createSubscriptionScenario({
      monthlyCredits: 5,
      monthlyPrice: 2500,
    });

    assertNotNull(scenario.package, "Should create subscription package");
    assertNotNull(scenario.user, "Should have test user");
    assertNotNull(scenario.purchase, "Should create initial purchase");
    assertEqual(
      scenario.package.is_recurring,
      true,
      "Package should be recurring"
    );
  });

  // Invoice Processing Tests
  suite.addTest("Should test invoice payment processing", async () => {
    const scenario = await fixtures.createSubscriptionScenario();

    // Test the process_invoice_paid function
    const { data: result, error } = await callFunction("process_invoice_paid", {
      p_stripe_customer_id: scenario.purchase.stripe_customer_id,
      p_amount_paid: scenario.package.price,
      p_currency: "usd",
      p_period_start: new Date().toISOString(),
      p_period_end: new Date(
        Date.now() + 30 * 24 * 60 * 60 * 1000
      ).toISOString(),
    });

    // Note: The actual behavior depends on the implementation
    // This test verifies the function can be called without error
    assert(!error, "process_invoice_paid should not error");
    log("Invoice processing test completed", "debug");
  });

  // Credit Refresh Tests
  suite.addTest(
    "Should test credit refresh for recurring subscriptions",
    async () => {
      const scenario = await fixtures.createSubscriptionScenario();

      // Test the refresh_universal_package_credits function
      const { data: result, error } = await callFunction(
        "refresh_universal_package_credits",
        {
          p_user_id: scenario.user.id,
          p_universal_package_id: scenario.package.id,
        }
      );

      // Note: The actual behavior depends on the implementation
      // This test verifies the function can be called without error
      assert(!error, "refresh_universal_package_credits should not error");
      log("Credit refresh test completed", "debug");
    }
  );

  return await suite.run();
}
