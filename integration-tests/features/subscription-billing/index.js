// Subscription Billing Feature - Entry Point

import { runSubscriptionTests } from "./tests/main-tests.js";
import { cleanup } from "./cleanup.js";
import { SubscriptionBillingFixtures } from "./fixtures.js";

// Feature metadata
export const metadata = {
  name: "Subscription Billing",
  description:
    "Tests subscription billing cycles, invoice processing, and credit refresh",
  dependencies: ["universal-packages"], // Depends on packages for credits
  cleanup_order: 2, // Clean after packages but before base data
};

// Main test runner
export async function runTests() {
  return await runSubscriptionTests();
}

// Export cleanup and fixtures for external use
export { cleanup };
export { SubscriptionBillingFixtures };
