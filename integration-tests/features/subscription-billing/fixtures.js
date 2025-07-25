// Subscription Billing Feature - Test Fixtures

import { TestFixtures } from "../../core/test-framework.js";
import { UniversalPackagesFixtures } from "../universal-packages/fixtures.js";
import { getSingleTestUser } from "../../config/test-users.js";
import { log } from "../../shared/utilities/test-utils.js";

/**
 * Test fixtures for Subscription Billing feature
 * Manages creation and cleanup of test data for subscription-related tests
 */
export class SubscriptionBillingFixtures extends TestFixtures {
  constructor() {
    super("subscription-billing");
    this.packageFixtures = new UniversalPackagesFixtures();
  }

  /**
   * Create a subscription billing scenario
   * @param {Object} options - Configuration options
   * @returns {Promise<Object>} Subscription scenario data
   */
  async createSubscriptionScenario(options = {}) {
    const { monthlyCredits = 5, monthlyPrice = 2500 } = options;

    log("Creating subscription billing test scenario...", "debug");

    // Create recurring package using the packages fixtures
    const package_ = await this.packageFixtures.createTestPackage({
      name: this.generateTestName("SubscriptionPackage"),
      credits: monthlyCredits,
      price: monthlyPrice,
      is_recurring: true,
      duration_months: 1,
    });

    const testUser = await getSingleTestUser();

    // Create initial subscription purchase
    const purchase = await this.packageFixtures.createTestPackagePurchase(
      package_.id,
      testUser.id,
      {
        stripe_customer_id: `cus_subscription_${Date.now()}`,
        payment_status: "succeeded",
      }
    );

    const scenario = {
      package: package_,
      user: testUser,
      purchase,
    };

    log("Subscription billing scenario created", "debug");
    return scenario;
  }

  /**
   * Clean up subscription billing test data
   * @returns {Promise<number>} Number of records cleaned
   */
  async cleanup() {
    // Delegate to package fixtures cleanup since we reuse their data
    const packageCleaned = await this.packageFixtures.cleanup();
    const baseCleaned = await super.cleanup();

    return packageCleaned + baseCleaned;
  }
}
