// Universal Packages Feature - Entry Point

import { createUniversalPackagesTests } from "./tests/index.js";
import { cleanup } from "./cleanup.js";
import { UniversalPackagesFixtures } from "./fixtures.js";

// Feature metadata
export const metadata = {
  name: "Universal Packages",
  description:
    "Tests universal package creation, purchase, and credit allocation",
  dependencies: [], // No dependencies
  cleanup_order: 3, // Higher number = cleaned first (packages contain credits)
};

/**
 * Run Universal Packages Integration Tests
 *
 * This feature tests the complete universal packages system including:
 * - Package creation and configuration
 * - Package purchasing and access management
 * - Credit consumption and tracking
 * - Stripe webhook processing
 * - Edge cases and error handling
 *
 * Tests are organized into focused files for maintainability:
 * - Each test category has its own file
 * - Clear separation of concerns
 * - Easy to debug and modify specific areas
 * - Comprehensive documentation for each test
 */
export async function runTests() {
  const testSuites = createUniversalPackagesTests();

  // Collect all results from all test suites
  let totalTests = 0;
  let passedTests = 0;
  let failedTests = 0;
  const allResults = [];

  console.log("📋 Running Organized Universal Packages Tests:");
  console.log("   📦 Package Creation, 💳 Purchasing, 🎯 Credit Consumption");
  console.log("   🔗 Webhook Processing, ⚠️ Edge Cases\n");

  for (const suite of testSuites) {
    console.log(`\n🧪 Running ${suite.name} tests...`);

    try {
      const results = await suite.run();

      // Count results
      totalTests += results.length;
      const suitePassedTests = results.filter((r) => r.success).length;
      const suiteFailedTests = results.filter((r) => !r.success).length;

      passedTests += suitePassedTests;
      failedTests += suiteFailedTests;

      allResults.push(...results);

      // Log suite summary
      console.log(
        `   ✅ ${suitePassedTests} passed, ❌ ${suiteFailedTests} failed`
      );
    } catch (error) {
      console.error(`❌ Error running ${suite.name}:`, error.message);
      failedTests++;
      allResults.push({
        name: `${suite.name} (Suite Error)`,
        success: false,
        error: error,
      });
    }
  }

  return {
    total: totalTests,
    passed: passedTests,
    failed: failedTests,
    results: allResults,
  };
}

// Export cleanup and fixtures for external use
export { cleanup };
export { UniversalPackagesFixtures };
