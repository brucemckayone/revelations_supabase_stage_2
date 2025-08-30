#!/usr/bin/env node

import { testConnection } from "./config/database.js";
import { log } from "./utils/test-helpers.js";
// import cleanupTestData from "./utils/cleanup.js"; // TODO: Fix cleanup import

// Import test modules
import { runCreditBookingTests } from "./features/credit-system/credit-booking-tests.js";
import { runTests as runEventsTests } from "./features/events/index.js";
import { runTests as runNotificationsTests } from "./features/notifications/index.js";

// Parse command line arguments
const args = process.argv.slice(2);
const feature = args.find((arg) => arg.startsWith("--feature="))?.split("=")[1];
const verbose = args.includes("--verbose");

// Global test results tracking
let globalResults = {
  suites: [],
  totalPassed: 0,
  totalFailed: 0,
  totalTests: 0,
  startTime: null,
  endTime: null,
  errors: [],
};

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
  events: {
    name: "Events System Tests",
    description:
      "Tests for event creation, booking, and universal package integration",
    runner: runEventsTests,
  },
  notifications: {
    name: "Notification System Tests",
    description:
      "Tests for multi-channel notification delivery, preferences, templates, and security",
    runner: runNotificationsTests,
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

function addSuiteResult(result) {
  globalResults.suites.push(result);
  globalResults.totalPassed += result.passed || 0;
  globalResults.totalFailed += result.failed || 0;
  globalResults.totalTests += result.total || 0;

  if (result.errors) {
    globalResults.errors.push(...result.errors);
  }
}

function printImprovedTestSummary() {
  globalResults.endTime = Date.now();
  const duration = globalResults.endTime - globalResults.startTime;

  console.log("\n" + "=".repeat(50));
  console.log("TEST SUMMARY");
  console.log("=".repeat(50));

  // Suite-by-suite summary
  for (const suite of globalResults.suites) {
    const status = suite.failed === 0 ? "✅" : "❌";
    const summary = `${suite.passed}/${suite.total} passed`;
    console.log(`${status} ${suite.suiteName}: ${summary}`);

    if (suite.failed > 0 && suite.errors) {
      for (const error of suite.errors) {
        console.log(`  └─ ${error.testName}: ${error.error}`);
      }
    }
  }

  console.log("-".repeat(50));

  // Overall summary
  if (globalResults.totalFailed === 0 && globalResults.totalTests > 0) {
    console.log(`🎉 All ${globalResults.totalTests} tests passed!`);
  } else {
    console.log(
      `❌ ${globalResults.totalFailed} of ${globalResults.totalTests} tests failed`
    );
    console.log(`✅ ${globalResults.totalPassed} tests passed`);
  }

  console.log(`⏱️  Duration: ${(duration / 1000).toFixed(2)}s`);
  const successRate =
    globalResults.totalTests > 0
      ? ((globalResults.totalPassed / globalResults.totalTests) * 100).toFixed(
          2
        )
      : 0;
  console.log(`📊 Success rate: ${successRate}%`);

  if (globalResults.errors.length > 0) {
    console.log("\n" + "=".repeat(50));
    console.log("DETAILED ERRORS");
    console.log("=".repeat(50));
    globalResults.errors.forEach((error, index) => {
      console.log(`${index + 1}. ${error.testName}`);
      console.log(`   Error: ${error.error}`);
      if (verbose && error.stack) {
        console.log(`   Stack: ${error.stack.split("\n")[0]}`);
      }
    });
  }

  console.log("=".repeat(50));

  return globalResults.totalFailed === 0;
}

async function main() {
  globalResults.startTime = Date.now();

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

      const result = await testFeature.runner();
      if (result) {
        addSuiteResult(result);
      }
    } else {
      // Run all tests
      log("Running all integration tests...", "info");

      for (const [featureKey, testFeature] of Object.entries(TEST_FEATURES)) {
        try {
          log(`\n📋 ${testFeature.name}`, "info");
          log(testFeature.description, "debug");
          log("-".repeat(50), "debug");

          const result = await testFeature.runner();
          if (result) {
            addSuiteResult(result);
          }
        } catch (error) {
          log(`Feature ${featureKey} failed: ${error.message}`, "error");
          // Add failed suite to results
          addSuiteResult({
            suiteName: testFeature.name,
            passed: 0,
            failed: 1,
            total: 1,
            errors: [{ testName: "Suite Execution", error: error.message }],
          });
          if (verbose) {
            console.error(error.stack);
          }
        }
      }
    }

    // Print improved test summary
    const success = printImprovedTestSummary();

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
