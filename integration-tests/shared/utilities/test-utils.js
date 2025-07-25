// Re-export existing test utilities for feature template compatibility
// This maintains backward compatibility while providing the expected interface
// all the files in this folder should be well document as to specify thre intended use and work flow why use some and not others etc
import {
  // Assertion functions
  assert,
  assertEqual,
  assertNotNull,
  assertGreaterThan,
  assertArrayLength,

  // Database utilities
  queryDatabase,
  callFunction,

  // Test lifecycle
  startTest,
  endTest,
  getTestResults,
  printTestSummary,

  // Test data generators
  generateTestData,
  getTestUsers,

  // Utilities
  delay,
  isValidUUID,
  formatCurrency,

  // Logging
  log,
} from "../../utils/test-helpers.js";

// Additional database utilities
import { supabase } from "../../config/database.js";

// Re-export all the utilities for feature templates
export {
  // Assertion functions
  assert,
  assertEqual,
  assertNotNull,
  assertGreaterThan,
  assertArrayLength,

  // Database utilities
  queryDatabase,
  callFunction,

  // Test lifecycle
  startTest,
  endTest,
  getTestResults,
  printTestSummary,

  // Test data generators
  generateTestData,
  getTestUsers,

  // Utilities
  delay,
  isValidUUID,
  formatCurrency,

  // Logging
  log,
};

/**
 * Insert a record into a database table
 * @param {string} table - Table name to insert into
 * @param {Object} data - Data to insert
 * @returns {Promise<Object>} Inserted record with generated fields
 */
export async function insertRecord(table, data) {
  try {
    log(`Inserting record into ${table}`, "debug");

    const { data: result, error } = await supabase
      .from(table)
      .insert(data)
      .select()
      .single();

    if (error) {
      log(`Failed to insert into ${table}: ${error.message}`, "error");
      throw error;
    }

    log(`Successfully inserted record into ${table}: ${result.id}`, "debug");
    return result;
  } catch (error) {
    log(`Error inserting into ${table}: ${error.message}`, "error");
    throw error;
  }
}

// Additional utility functions for feature tests
export function createTestId(prefix = "TEST_") {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(7);
  return `${prefix}${timestamp}_${random}`;
}

export function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// Test data validation helpers
export function validateTestData(data, schema) {
  const errors = [];

  for (const [key, validator] of Object.entries(schema)) {
    if (typeof validator === "function") {
      if (!validator(data[key])) {
        errors.push(`Invalid ${key}: ${data[key]}`);
      }
    } else if (validator.required && !data[key]) {
      errors.push(`Missing required field: ${key}`);
    }
  }

  return errors;
}
