import chalk from "chalk";
import { supabase, TEST_CONFIG } from "../config/database.js";

/**
 * Test Utilities - Main testing library for integration tests
 *
 * This module provides:
 * - Beautiful, indented test output with color coding
 * - Assertion functions with clear pass/fail indicators
 * - Database utilities that integrate with existing test-users.js
 * - Test lifecycle management (start/end test tracking)
 * - Scoped logging (sections, requirements, actions, verifications)
 *
 * Usage:
 * - Import specific functions you need from shared/utilities/test-utils.js
 * - Use startTest()/endTest() to wrap individual test functions
 * - Use logSection(), logRequirement(), logAction(), logVerify() for structure
 * - Use assert(), assertEqual(), etc. for validations
 */

// Test state tracking
let testResults = {
  passed: 0,
  failed: 0,
  total: 0,
  startTime: null,
  currentTest: null,
  currentTestPassed: 0,
  currentTestFailed: 0,
};

function scopePrefix(level) {
  // Indent anything that happens inside a test for readability
  if (!testResults.currentTest) return "";
  // Stronger indent for granular lines
  const base = "  ";
  if (level === "section") return base; // one level
  return base + "  "; // two levels
}

// Logging utilities
export function log(message, level = "info") {
  if (!TEST_CONFIG.VERBOSE && level === "debug") return;

  const timestamp = new Date().toISOString().split("T")[1].split(".")[0];
  const basePrefix = `[${timestamp}]`;
  const indent = scopePrefix(level);

  switch (level) {
    case "success":
      console.log(chalk.green(`${basePrefix} ${indent}✅ ${message}`));
      break;
    case "error":
      console.log(chalk.red(`${basePrefix} ${indent}❌ ${message}`));
      break;
    case "expected_failure":
      console.log(chalk.magenta(`${basePrefix} ${indent}🎯 ${message}`));
      break;
    case "warning":
      console.log(chalk.yellow(`${basePrefix} ${indent}⚠️  ${message}`));
      break;
    case "debug":
      console.log(chalk.gray(`${basePrefix} ${indent}🔍 ${message}`));
      break;
    case "section":
      console.log(chalk.cyan(`${basePrefix} ${indent}▶ ${message}`));
      break;
    default:
      console.log(chalk.blue(`${basePrefix} ${indent}ℹ️  ${message}`));
  }
}

// Scoped helpers for clearer structure
export const logSection = (title) => log(title, "section");
export const logRequirement = (msg) => log(`REQ: ${msg}`, "info");
export const logAction = (msg) => log(`ACT: ${msg}`, "info");
export const logVerify = (msg) => log(`VER: ${msg}`, "info");
export const logExpectedFailure = (msg) =>
  log(`EXPECTED: ${msg}`, "expected_failure");

// Get file link for clickable navigation in VS Code/Cursor
function getFileLink(filename, line = 1) {
  // Create a clickable file link - works in VS Code/Cursor terminal
  const workspaceRoot =
    "/Users/brucemckay/Desktop/nightmare/revelations/supabase/integration-tests";
  const relativePath = filename.replace(workspaceRoot + "/", "");
  return `${relativePath}:${line}`;
}

// Test assertion functions with compact output
export function assert(condition, message, isExpectedFailure = false) {
  testResults.total++;

  if (condition) {
    testResults.passed++;
    testResults.currentTestPassed++;
    // Always show assertions, but keep them compact and indented
    if (isExpectedFailure) {
      console.log(chalk.magenta(`${scopePrefix("assert")}🎯 ${message}`));
    } else {
      console.log(chalk.green(`${scopePrefix("assert")}✓ ${message}`));
    }
  } else {
    testResults.failed++;
    testResults.currentTestFailed++;

    if (isExpectedFailure) {
      console.log(chalk.magenta(`${scopePrefix("assert")}🎯 ${message}`));
    } else {
      // Get stack trace to find the test file
      const stack = new Error().stack;
      const testFileMatch = stack.match(
        /at .*\/(features\/.*\.test\.js):(\d+):\d+/
      );
      const fileInfo = testFileMatch
        ? ` (${getFileLink(testFileMatch[1], testFileMatch[2])})`
        : "";

      console.log(chalk.red(`${scopePrefix("assert")}✗ ${message}${fileInfo}`));
      throw new Error(`${message}${fileInfo}`);
    }
  }

  return condition;
}

export function assertEqual(
  actual,
  expected,
  message,
  isExpectedFailure = false
) {
  const condition = actual === expected;
  const fullMessage = condition
    ? message
    : `${message} (Expected: ${expected}, Got: ${actual})`;
  return assert(condition, fullMessage, isExpectedFailure);
}

export function assertNotNull(value, message, isExpectedFailure = false) {
  return assert(
    value !== null && value !== undefined,
    message,
    isExpectedFailure
  );
}

export function assertGreaterThan(
  actual,
  expected,
  message,
  isExpectedFailure = false
) {
  const condition = actual > expected;
  const fullMessage = condition
    ? message
    : `${message} (Expected > ${expected}, Got: ${actual})`;
  return assert(condition, fullMessage, isExpectedFailure);
}

export function assertArrayLength(
  array,
  expectedLength,
  message,
  isExpectedFailure = false
) {
  return assertEqual(array.length, expectedLength, message, isExpectedFailure);
}

// Helper for expected failures (validation tests)
export function assertExpectedFailure(condition, message) {
  return assert(condition, message, true);
}

// Test lifecycle management
export function startTest(testName) {
  testResults.currentTest = testName;
  testResults.currentTestPassed = 0;
  testResults.currentTestFailed = 0;

  if (!testResults.startTime) {
    testResults.startTime = Date.now();
  }
  // Clear header for the test
  console.log("\n" + chalk.bold(`» Test: ${testName}`));
}

export function endTest() {
  if (testResults.currentTest) {
    // Show test completion summary
    const total = testResults.currentTestPassed + testResults.currentTestFailed;
    if (testResults.currentTestFailed === 0) {
      log(
        `✓ Completed: ${testResults.currentTestPassed}/${total} checks passed`,
        "success"
      );
    } else {
      log(
        `✗ Completed: ${testResults.currentTestFailed}/${total} checks failed`,
        "error"
      );
    }

    testResults.currentTest = null;
    testResults.currentTestPassed = 0;
    testResults.currentTestFailed = 0;
  }
}

export function getTestResults() {
  const duration = testResults.startTime
    ? Date.now() - testResults.startTime
    : 0;
  return {
    ...testResults,
    duration,
    successRate:
      testResults.total > 0
        ? ((testResults.passed / testResults.total) * 100).toFixed(2)
        : 0,
  };
}

export function printTestSummary() {
  const results = getTestResults();

  console.log("\n" + "=".repeat(50));
  console.log(chalk.bold("TEST SUMMARY"));
  console.log("=".repeat(50));

  if (results.passed === results.total && results.total > 0) {
    console.log(chalk.green(`🎉 All ${results.total} tests passed!`));
  } else {
    console.log(
      chalk.red(`❌ ${results.failed} of ${results.total} tests failed`)
    );
    console.log(chalk.green(`✅ ${results.passed} tests passed`));
  }

  console.log(`⏱️  Duration: ${(results.duration / 1000).toFixed(2)}s`);
  console.log(`📊 Success rate: ${results.successRate}%`);
  console.log("=".repeat(50));

  return results.failed === 0;
}

// Database test utilities

export async function callFunction(
  functionName,
  params = {},
  isExpectedFailure = false
) {
  try {
    log(`Calling function: ${functionName}`, "debug");
    const { data, error } = await supabase.rpc(functionName, params);

    if (error) {
      throw error;
    }

    log(
      `Function ${functionName} returned: ${JSON.stringify(data).substring(
        0,
        200
      )}...`,
      "debug"
    );
    return { data, error: null };
  } catch (error) {
    if (isExpectedFailure) {
      log(
        `Function ${functionName} failed: ${error.message}`,
        "expected_failure"
      );
    } else {
      log(`Function ${functionName} failed: ${error.message}`, "error");
    }
    return { data: null, error };
  }
}

// Test data generators
export function generateTestData() {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(7);

  return {
    // Universal package data
    package: {
      name: `${TEST_CONFIG.TEST_PREFIX}Package_${timestamp}`,
      description: "Test package for integration testing",
      price: 5000, // $50.00 in cents
      credits: 10,
      duration_months: 1,
      is_recurring: false,
      creator_id: TEST_CONFIG.CREATOR_USER_ID,
      event_access_config: {
        max_events_per_month: 5,
        eligible_event_types: ["workshop", "consultation"],
      },
    },

    // Event data
    event: {
      title: `${TEST_CONFIG.TEST_PREFIX}Event_${timestamp}`,
      description: "Test event for integration testing",
      creator_id: TEST_CONFIG.CREATOR_USER_ID,
      category: "workshop",
      is_public: true,
      status: "published",
    },

    // Purchase data
    purchase: {
      payment_intent_id: `pi_test_${random}`,
      amount: 5000,
      currency: "usd",
      status: "succeeded",
    },

    // Booking data
    booking: {
      booking_code: `${TEST_CONFIG.TEST_PREFIX}${random}`.toUpperCase(),
      attendee_name: "Test User",
      attendee_email: "test@example.com",
    },
  };
}

// Test user utilities - integrate with existing test-users.js
export async function getTestUsers(count = 5) {
  try {
    // Use simple database query to get test users
    const { data: users, error } = await supabase
      .from("auth.users")
      .select("id, email")
      .neq("id", TEST_CONFIG.CREATOR_USER_ID)
      .limit(count);

    if (error) throw error;

    return users || [];
  } catch (error) {
    log(`Failed to get test users: ${error.message}`, "error");
    return [];
  }
}

// Database query function with logging integration
export async function queryDatabase(sql, params = []) {
  try {
    log(`Executing query: ${sql.substring(0, 100)}...`, "debug");
    const { data, error } = await supabase.rpc("exec_sql", {
      sql_query: sql,
      params: params,
    });

    if (error) {
      throw error;
    }

    return { data, error: null };
  } catch (error) {
    log(`Database query failed: ${error.message}`, "error");
    return { data: null, error };
  }
}

// Async delay utility
export function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// UUID validation
export function isValidUUID(uuid) {
  const uuidRegex =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
}

// Currency formatting
export function formatCurrency(cents) {
  return `$${(cents / 100).toFixed(2)}`;
}

export default {
  log,
  logSection,
  logRequirement,
  logAction,
  logVerify,
  assert,
  assertEqual,
  assertNotNull,
  assertGreaterThan,
  assertArrayLength,
  startTest,
  endTest,
  getTestResults,
  printTestSummary,
  queryDatabase,
  callFunction,
  generateTestData,
  getTestUsers,
  delay,
  isValidUUID,
  formatCurrency,
};
