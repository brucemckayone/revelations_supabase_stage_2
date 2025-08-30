#!/usr/bin/env node

import { testConnection } from "./config/database.js";
import { log, printTestSummary } from "./utils/test-helpers.js";
import {
  runTests as runEventsTests,
  metadata,
} from "./features/events/index.js";

async function runEventTests() {
  console.log("🧪 Integration Tests for Events System");
  console.log("=====================================");
  console.log("");
  console.log(`📋 ${metadata.name}`);
  console.log(`${metadata.description}`);
  console.log("--------------------------------------------------");
  console.log("");

  try {
    // Test database connection
    log("Testing database connection...", "info");
    await testConnection();
    log("Database connection successful ✅", "success");
    console.log("");

    // Run the events tests
    const result = await runEventsTests();

    // Print summary
    console.log("");
    console.log("==================================================");
    console.log("TEST SUMMARY");
    console.log("==================================================");

    if (result.success) {
      log(`🎉 All ${result.testsRun} tests passed!`, "success");
      log(`⏱️  Duration: ${result.duration}s`, "info");
      log(`📊 Success rate: ${result.successRate}%`, "info");
    } else {
      log(
        `❌ ${result.testsFailed} of ${result.testsRun} tests failed`,
        "error"
      );
      log(`⏱️  Duration: ${result.duration}s`, "info");
      log(`📊 Success rate: ${result.successRate}%`, "info");

      if (result.errors && result.errors.length > 0) {
        console.log("");
        log("Errors:", "error");
        result.errors.forEach((error) => {
          console.log(`  • ${error}`);
        });
      }
    }

    console.log("==================================================");
    console.log("");

    // Exit with appropriate code
    process.exit(result.success ? 0 : 1);
  } catch (error) {
    log(`Test execution failed: ${error.message}`, "error");
    console.error(error);
    process.exit(1);
  }
}

// Run the tests
runEventTests();
