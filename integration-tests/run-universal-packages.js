#!/usr/bin/env node

// Test Runner for Universal Packages Feature
// Runs all universal packages integration tests

import { createUniversalPackagesTests } from "./features/universal-packages/tests/index.js";

async function runUniversalPackagesTests() {
  console.log("🧪 Running Universal Packages Integration Tests\n");
  console.log("📋 Test Organization:");
  console.log("   📦 Package Creation Tests");
  console.log("   💳 Package Purchasing Tests");
  console.log("   🎯 Credit Consumption Tests");
  console.log("   🔗 Webhook Processing Tests");
  console.log("   ⚠️  Edge Cases Tests");
  console.log("");

  // Get all organized test suites
  const testSuites = createUniversalPackagesTests();

  let totalPassed = 0;
  let totalFailed = 0;
  let totalTests = 0;
  const allErrors = [];

  // Run each test suite
  for (const suite of testSuites) {
    try {
      console.log(`\n🧪 Running ${suite.name} tests...`);
      const results = await suite.run();

      totalPassed += results.passed;
      totalFailed += results.failed;
      totalTests += results.total;

      if (results.errors && results.errors.length > 0) {
        allErrors.push(
          ...results.errors.map((err) => ({ ...err, suite: suite.name }))
        );
      }
    } catch (error) {
      console.error(`❌ Error running ${suite.name}:`, error.message);
      totalFailed++;
      allErrors.push({
        suite: suite.name,
        testName: "Suite Error",
        error: error.message,
        stack: error.stack,
      });
    }
  }

  // Final summary
  console.log(`\n${"=".repeat(60)}`);
  console.log(`📊 FINAL RESULTS:`);
  console.log(`   Total Tests: ${totalTests}`);
  console.log(`   ✅ Passed: ${totalPassed}`);
  console.log(`   ❌ Failed: ${totalFailed}`);

  if (totalTests > 0) {
    const successRate = ((totalPassed / totalTests) * 100).toFixed(1);
    console.log(`   📈 Success Rate: ${successRate}%`);
  }

  // Show errors if any
  if (allErrors.length > 0) {
    console.log(`\n❌ ERROR DETAILS:`);
    allErrors.forEach((err, index) => {
      console.log(`\n${index + 1}. ${err.suite} - ${err.testName}:`);
      console.log(`   ${err.error}`);
    });
  }

  const success = totalFailed === 0;
  if (success) {
    console.log("\n✅ All Universal Packages tests passed!");
  } else {
    console.log("\n❌ Some Universal Packages tests failed.");
    process.exit(1);
  }
}

// Only run if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  runUniversalPackagesTests().catch((error) => {
    console.error("💥 Test execution failed:", error);
    process.exit(1);
  });
}
