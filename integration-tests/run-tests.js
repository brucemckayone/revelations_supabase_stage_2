#!/usr/bin/env node

import { testConnection } from "./config/database.js";
import { log, printTestSummary } from "./utils/test-helpers.js";
import cleanupTestData from "./utils/cleanup.js";

// Import test modules
import { runCreditBookingTests } from "./features/credit-system/credit-booking-tests.js";

// Parse command line arguments
const args = process.argv.slice(2);
const feature = args.find((arg) => arg.startsWith("--feature="))?.split("=")[1];
const verbose = args.includes("--verbose");

// Available test features
const TEST_FEATURES = {
  "credit-system": {
    name: "Credit System Tests",
    description: "Tests for credit booking and consumption functions",
    runner: runCreditBookingTests,
  },
  "universal-packages": {
    name: "Universal Packages Tests",
    description: "Tests for package creation and management",
    runner: async () =>
      log("Universal packages tests not yet implemented", "warning"),
  },
  "subscription-billing": {
    name: "Subscription Billing Tests",
    description: "Tests for recurring billing and credit refresh",
    runner: async () =>
      log("Subscription billing tests not yet implemented", "warning"),
  },
  "event-booking": {
    name: "Event Booking Tests",
    description: "Tests for direct event purchases and bookings",
    runner: async () =>
      log("Event booking tests not yet implemented", "warning"),
  },
  "webhook-processing": {
    name: "Webhook Processing Tests",
    description: "Tests for payment webhook simulation",
    runner: async () =>
      log("Webhook processing tests not yet implemented", "warning"),
  },
  "error-handling": {
    name: "Error Handling Tests",
    description: "Tests for edge cases and error scenarios",
    runner: async () =>
      log("Error handling tests not yet implemented", "warning"),
  },
};

async function main() {
  console.log("🧪 Payment System Integration Tests");
  console.log("=====================================\n");

  // Test database connection
  log("Testing database connection...", "info");
  const connectionOk = await testConnection();
  if (!connectionOk) {
    log("Cannot proceed without database connection", "error");
    process.exit(1);
  }

  try {
    if (feature) {
      // Run specific feature tests
      if (!TEST_FEATURES[feature]) {
        log(`Unknown feature: ${feature}`, "error");
        log(
          `Available features: ${Object.keys(TEST_FEATURES).join(", ")}`,
          "info"
        );
        process.exit(1);
      }

      const testFeature = TEST_FEATURES[feature];
      log(`Running ${testFeature.name}...`, "info");
      log(testFeature.description, "debug");

      await testFeature.runner();
    } else {
      // Run all tests
      log("Running all integration tests...", "info");

      for (const [featureKey, testFeature] of Object.entries(TEST_FEATURES)) {
        try {
          log(`\n📋 ${testFeature.name}`, "info");
          log(testFeature.description, "debug");
          log("-".repeat(50), "debug");

          await testFeature.runner();
        } catch (error) {
          log(`Feature ${featureKey} failed: ${error.message}`, "error");
          if (verbose) {
            console.error(error.stack);
          }
        }
      }
    }

    // Print test summary
    const success = printTestSummary();

    if (success) {
      log("\n🎉 All tests passed!", "success");
      process.exit(0);
    } else {
      log("\n❌ Some tests failed", "error");
      process.exit(1);
    }
  } catch (error) {
    log(`Test execution failed: ${error.message}`, "error");
    if (verbose) {
      console.error(error.stack);
    }
    process.exit(1);
  } finally {
    // Final cleanup
    try {
      log("\n🧹 Final cleanup...", "info");
      await cleanupTestData();
    } catch (cleanupError) {
      log(`Cleanup failed: ${cleanupError.message}`, "warning");
    }
  }
}

// Display help information
function showHelp() {
  console.log(`
Payment System Integration Tests

Usage:
  node run-tests.js [options]

Options:
  --feature=<name>    Run tests for specific feature only
  --verbose           Enable verbose logging
  --help              Show this help message

Available Features:
${Object.entries(TEST_FEATURES)
  .map(([key, feature]) => `  ${key.padEnd(20)} ${feature.description}`)
  .join("\n")}

Examples:
  node run-tests.js                           # Run all tests
  node run-tests.js --feature=credit-system  # Run only credit system tests
  node run-tests.js --verbose                # Run with detailed logging
  node run-tests.js --feature=credit-system --verbose

Environment Setup:
  Create a .env file with:
    SUPABASE_URL=your_supabase_url
    SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
`);
}

// Handle help command
if (args.includes("--help") || args.includes("-h")) {
  showHelp();
  process.exit(0);
}

// Handle process signals for cleanup
process.on("SIGINT", async () => {
  log("\n🛑 Test execution interrupted", "warning");
  try {
    await cleanupTestData();
    log("Cleanup completed", "success");
  } catch (error) {
    log(`Cleanup failed: ${error.message}`, "error");
  }
  process.exit(1);
});

process.on("SIGTERM", async () => {
  log("\n🛑 Test execution terminated", "warning");
  try {
    await cleanupTestData();
    log("Cleanup completed", "success");
  } catch (error) {
    log(`Cleanup failed: ${error.message}`, "error");
  }
  process.exit(1);
});

// Run main function
main().catch((error) => {
  console.error("❌ Unhandled error:", error);
  process.exit(1);
});
