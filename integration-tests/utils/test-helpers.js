import chalk from "chalk";
import { supabase, TEST_CONFIG } from "../config/database.js";
// all the files in this folder should be well document as to specify thre intended use and work flow why use some and not others etc
// Test state tracking
let testResults = {
  passed: 0,
  failed: 0,
  total: 0,
  startTime: null,
  currentTest: null,
};

// Logging utilities
export function log(message, level = "info") {
  if (!TEST_CONFIG.VERBOSE && level === "debug") return;

  const timestamp = new Date().toISOString().split("T")[1].split(".")[0];
  const prefix = `[${timestamp}]`;

  switch (level) {
    case "success":
      console.log(chalk.green(`${prefix} ✅ ${message}`));
      break;
    case "error":
      console.log(chalk.red(`${prefix} ❌ ${message}`));
      break;
    case "warning":
      console.log(chalk.yellow(`${prefix} ⚠️  ${message}`));
      break;
    case "debug":
      console.log(chalk.gray(`${prefix} 🔍 ${message}`));
      break;
    default:
      console.log(chalk.blue(`${prefix} ℹ️  ${message}`));
  }
}

// Test assertion functions
export function assert(condition, message) {
  if (condition) {
    log(`PASS: ${message}`, "success");
    testResults.passed++;
  } else {
    log(`FAIL: ${message}`, "error");
    testResults.failed++;
    throw new Error(message);
  }
  testResults.total++;
  return condition;
}

export function assertEqual(actual, expected, message) {
  const condition = actual === expected;
  const fullMessage = condition
    ? message
    : `${message} (Expected: ${expected}, Got: ${actual})`;
  return assert(condition, fullMessage);
}

export function assertNotNull(value, message) {
  return assert(value !== null && value !== undefined, message);
}

export function assertGreaterThan(actual, expected, message) {
  const condition = actual > expected;
  const fullMessage = condition
    ? message
    : `${message} (Expected > ${expected}, Got: ${actual})`;
  return assert(condition, fullMessage);
}

export function assertArrayLength(array, expectedLength, message) {
  return assertEqual(array.length, expectedLength, message);
}

// Test lifecycle management
export function startTest(testName) {
  testResults.currentTest = testName;
  if (!testResults.startTime) {
    testResults.startTime = Date.now();
  }
  log(`Starting test: ${testName}`, "info");
}

export function endTest() {
  if (testResults.currentTest) {
    log(`Completed test: ${testResults.currentTest}`, "debug");
    testResults.currentTest = null;
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

export async function callFunction(functionName, params = {}) {
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
    log(`Function ${functionName} failed: ${error.message}`, "error");
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

// Test user utilities
export async function getTestUsers(count = 5) {
  try {
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
