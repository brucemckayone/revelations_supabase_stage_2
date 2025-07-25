// Universal Packages - Webhook Processing Tests
// Tests for Stripe webhook processing and payment integration

import { TestSuite } from "../../../core/test-framework.js";
import { UniversalPackagesFixtures } from "../fixtures.js";
import {
  assert,
  assertEqual,
  assertNotNull,
  log,
} from "../../../shared/utilities/test-utils.js";

export function createWebhookProcessingTests() {
  const suite = new TestSuite("Webhook Processing");
  const fixtures = new UniversalPackagesFixtures();

  /**
   * TEST: Stripe Webhook Payment Success Processing
   *
   * WHAT: Tests that successful Stripe payments create universal package purchases
   * WHY: Webhook processing is critical for converting payments into actual
   *      package access - without this, users pay but get nothing
   * VALIDATES:
   * - Webhook payload parsing and validation
   * - Purchase record creation from payment success
   * - Credit allocation based on purchased package
   * - Payment-to-purchase relationship establishment
   * - Webhook idempotency (duplicate webhooks don't create duplicate purchases)
   */
  suite.addTest("Should process Stripe payment success webhook", async () => {
    // Create a package to be purchased
    const package_ = await fixtures.createTestPackage({
      name: fixtures.generateTestName("WebhookTestPackage"),
      total_event_credits: 10,
      one_time_price: 5000, // $50.00
    });

    // Simulate Stripe webhook payload for successful payment
    const webhookPayload = {
      type: "checkout.session.completed",
      data: {
        object: {
          id: "cs_test_" + fixtures.generateUniqueId(),
          payment_status: "paid",
          metadata: {
            package_id: package_.id,
            user_id: fixtures.testUsers.customer1.id,
          },
          amount_total: 5000,
          currency: "usd",
        },
      },
    };

    // Process the webhook
    const result = await fixtures.processStripeWebhook(webhookPayload);

    // Validate webhook processing result
    assert(result.success, "Webhook processing should succeed");
    assert(result.purchase_id, "Should return purchase ID");

    // Validate purchase was created
    const purchase = await fixtures.getPurchase(result.purchase_id);
    assert(purchase, "Purchase should be created from webhook");
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
    assertEqual(
      purchase.remaining_event_credits,
      10,
      "Purchase should have correct initial credits"
    );
  });

  /**
   * TEST: Webhook Duplicate Protection
   *
   * WHAT: Tests that duplicate webhook calls don't create duplicate purchases
   * WHY: Stripe may send the same webhook multiple times, and we must ensure
   *      this doesn't result in duplicate purchases or credit allocation
   * VALIDATES:
   * - Webhook idempotency mechanisms
   * - Duplicate webhook detection
   * - Single purchase creation despite multiple webhooks
   * - Consistent system state under webhook replay scenarios
   */
  suite.addTest("Should handle duplicate webhooks gracefully", async () => {
    const package_ = await fixtures.createTestPackage({
      name: fixtures.generateTestName("DuplicateWebhookPackage"),
      total_event_credits: 5,
      one_time_price: 2500,
    });

    const webhookPayload = {
      type: "checkout.session.completed",
      data: {
        object: {
          id: "cs_test_duplicate_" + fixtures.generateUniqueId(),
          payment_status: "paid",
          metadata: {
            package_id: package_.id,
            user_id: fixtures.testUsers.customer1.id,
          },
          amount_total: 2500,
          currency: "usd",
        },
      },
    };

    // Process webhook first time
    const result1 = await fixtures.processStripeWebhook(webhookPayload);
    assert(result1.success, "First webhook processing should succeed");

    // Process same webhook again (duplicate)
    const result2 = await fixtures.processStripeWebhook(webhookPayload);
    assert(result2.success, "Duplicate webhook should be handled gracefully");

    // Verify only one purchase was created
    const purchases = await fixtures.getPurchasesForUser(
      fixtures.testUsers.customer1.id
    );
    const packagePurchases = purchases.filter(
      (p) => p.package_id === package_.id
    );
    assertEqual(
      packagePurchases.length,
      1,
      "Should have only one purchase despite duplicate webhooks"
    );
  });

  /**
   * TEST: Webhook Payment Failure Handling
   *
   * WHAT: Tests handling of failed payment webhooks
   * WHY: Not all payments succeed, and system must properly handle failures
   *      without creating purchases or allocating credits
   * VALIDATES:
   * - Failed payment webhook recognition
   * - No purchase creation on payment failure
   * - Error logging and notification
   * - System integrity during payment failures
   */
  suite.addTest("Should handle payment failure webhooks", async () => {
    const package_ = await fixtures.createTestPackage({
      name: fixtures.generateTestName("FailedPaymentPackage"),
      total_event_credits: 3,
      one_time_price: 1500,
    });

    const failedWebhookPayload = {
      type: "checkout.session.completed",
      data: {
        object: {
          id: "cs_test_failed_" + fixtures.generateUniqueId(),
          payment_status: "unpaid",
          metadata: {
            package_id: package_.id,
            user_id: fixtures.testUsers.customer1.id,
          },
          amount_total: 1500,
          currency: "usd",
        },
      },
    };

    // Process failed payment webhook
    const result = await fixtures.processStripeWebhook(failedWebhookPayload);

    // Validate no purchase was created
    assert(
      !result.success || !result.purchase_id,
      "Failed payment should not create purchase"
    );

    // Verify no purchase exists for this user/package combination
    const purchases = await fixtures.getPurchasesForUser(
      fixtures.testUsers.customer1.id
    );
    const packagePurchases = purchases.filter(
      (p) => p.package_id === package_.id
    );
    assertEqual(
      packagePurchases.length,
      0,
      "Should have no purchases for failed payment"
    );
  });

  /**
   * TEST: Webhook Subscription Processing
   *
   * WHAT: Tests processing of recurring subscription webhooks
   * WHY: Recurring packages require different webhook handling than one-time
   *      purchases, including subscription management and renewal processing
   * VALIDATES:
   * - Subscription creation webhook handling
   * - Recurring purchase record creation
   * - Subscription-specific metadata processing
   * - Recurring billing cycle management
   */
  suite.addTest("Should process subscription webhooks", async () => {
    const package_ = await fixtures.createTestPackage({
      name: fixtures.generateTestName("SubscriptionPackage"),
      total_event_credits: 15,
      supports_recurring_purchase: true,
      recurring_price: 3000, // $30.00/month
      duration_weeks: null, // Ongoing
    });

    const subscriptionWebhookPayload = {
      type: "customer.subscription.created",
      data: {
        object: {
          id: "sub_test_" + fixtures.generateUniqueId(),
          status: "active",
          metadata: {
            package_id: package_.id,
            user_id: fixtures.testUsers.customer1.id,
          },
          plan: {
            amount: 3000,
            currency: "usd",
            interval: "month",
          },
        },
      },
    };

    // Process subscription webhook
    const result = await fixtures.processStripeWebhook(
      subscriptionWebhookPayload
    );

    // Validate subscription processing
    assert(result.success, "Subscription webhook processing should succeed");
    assert(result.purchase_id, "Should create purchase for subscription");

    // Validate purchase was created with correct properties
    const purchase = await fixtures.getPurchase(result.purchase_id);
    assert(purchase, "Purchase should be created for subscription");
    assertEqual(
      purchase.remaining_event_credits,
      15,
      "Should have correct subscription credits"
    );
    assert(
      !purchase.expires_at,
      "Subscription should not have expiration date"
    );
  });

  // Cleanup after all tests
  suite.afterAll(async () => {
    await fixtures.cleanup();
  });

  return suite;
}
