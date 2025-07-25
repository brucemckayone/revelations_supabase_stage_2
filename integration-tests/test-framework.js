#!/usr/bin/env node

// Test Framework Validation Script
// This script tests that our new modular framework works correctly

import { testConnection } from "./config/database.js";
import { cleanupCoordinator } from "./core/cleanup-coordinator.js";
import {
  metadata as packagesMetadata,
  runTests as runPackageTests,
  cleanup as packagesCleanup,
} from "./features/universal-packages/index.js";
import {
  metadata as subscriptionMetadata,
  runTests as runSubscriptionTests,
  cleanup as subscriptionCleanup,
} from "./features/subscription-billing/index.js";
import { log, printTestSummary } from "./shared/utilities/test-utils.js";

async function main() {
  try {
    console.log("🚀 Testing Integration Framework...\n");

    // 1. Test database connection
    log("Testing database connection...", "info");
    const connected = await testConnection();
    if (!connected) {
      throw new Error("Database connection failed");
    }

    // 2. Register features with cleanup coordinator
    log("Registering features with cleanup coordinator...", "info");
    cleanupCoordinator.registerFeature(
      "universal-packages",
      packagesCleanup,
      packagesMetadata.cleanup_order,
      packagesMetadata.dependencies
    );

    cleanupCoordinator.registerFeature(
      "subscription-billing",
      subscriptionCleanup,
      subscriptionMetadata.cleanup_order,
      subscriptionMetadata.dependencies
    );

    // 3. Show cleanup coordinator status
    const status = cleanupCoordinator.getStatus();
    log(`Registered ${status.totalFeatures} features for testing`, "info");
    log(`Cleanup order: ${status.cleanupOrder.join(" → ")}`, "info");

    // 4. Run Universal Packages tests
    log("\n📦 Running Universal Packages tests...", "info");
    const packageResults = await runPackageTests();

    if (packageResults.failed > 0) {
      log(
        `❌ Universal Packages tests failed: ${packageResults.failed}/${packageResults.total}`,
        "error"
      );
      packageResults.errors.forEach((error) => {
        log(`  - ${error.testName}: ${error.error}`, "error");
      });
    } else {
      log(
        `✅ Universal Packages tests passed: ${packageResults.passed}/${packageResults.total}`,
        "success"
      );
    }

    // 5. Run Subscription Billing tests
    log("\n💳 Running Subscription Billing tests...", "info");
    const subscriptionResults = await runSubscriptionTests();

    if (subscriptionResults.failed > 0) {
      log(
        `❌ Subscription Billing tests failed: ${subscriptionResults.failed}/${subscriptionResults.total}`,
        "error"
      );
      subscriptionResults.errors.forEach((error) => {
        log(`  - ${error.testName}: ${error.error}`, "error");
      });
    } else {
      log(
        `✅ Subscription Billing tests passed: ${subscriptionResults.passed}/${subscriptionResults.total}`,
        "success"
      );
    }

    // 6. Test coordinated cleanup
    log("\n🧹 Testing coordinated cleanup...", "info");
    const cleanupResults = await cleanupCoordinator.cleanupAll();

    if (cleanupResults.failedFeatures > 0) {
      log(
        `❌ Cleanup failed for ${cleanupResults.failedFeatures} features`,
        "error"
      );
    } else {
      log(
        `✅ Cleanup completed successfully for all ${cleanupResults.successfulFeatures} features`,
        "success"
      );
      log(
        `📊 Total records cleaned: ${cleanupResults.totalRecordsCleaned}`,
        "info"
      );
    }

    // 7. Print summary
    const totalTests = packageResults.total + subscriptionResults.total;
    const totalPassed = packageResults.passed + subscriptionResults.passed;
    const totalFailed = packageResults.failed + subscriptionResults.failed;

    console.log("\n" + "=".repeat(60));
    console.log("🎯 INTEGRATION FRAMEWORK TEST SUMMARY");
    console.log("=".repeat(60));
    console.log(
      `📦 Universal Packages: ${packageResults.passed}/${packageResults.total} passed`
    );
    console.log(
      `💳 Subscription Billing: ${subscriptionResults.passed}/${subscriptionResults.total} passed`
    );
    console.log(
      `🧹 Cleanup: ${cleanupResults.successfulFeatures}/${cleanupResults.totalFeatures} features`
    );
    console.log(`📊 Overall: ${totalPassed}/${totalTests} tests passed`);

    if (totalFailed === 0 && cleanupResults.failedFeatures === 0) {
      console.log("\n🎉 Integration framework working perfectly!");
      process.exit(0);
    } else {
      console.log("\n❌ Integration framework has issues that need fixing.");
      process.exit(1);
    }
  } catch (error) {
    console.error("\n💥 Framework test failed:", error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

// Run the test
main();
