import { supabase, TEST_CONFIG } from "../config/database.js";
import { log, startTest, endTest } from "../shared/utilities/test-utils.js";

/**
 * Base TestSuite class for organizing and running feature tests
 */
export class TestSuite {
  constructor(name, description) {
    this.name = name;
    this.description = description;
    this.tests = [];
    this.beforeEachCallbacks = [];
    this.afterEachCallbacks = [];
    this.beforeAllCallbacks = [];
    this.afterAllCallbacks = [];
  }

  /**
   * Add a test to the suite
   * @param {string} name - Test name
   * @param {Function} testFn - Test function
   */
  addTest(name, testFn) {
    this.tests.push({ name, testFn });
  }

  /**
   * Add callback to run before each test
   * @param {Function} callback - Callback function
   */
  beforeEach(callback) {
    this.beforeEachCallbacks.push(callback);
  }

  /**
   * Add callback to run after each test
   * @param {Function} callback - Callback function
   */
  afterEach(callback) {
    this.afterEachCallbacks.push(callback);
  }

  /**
   * Add callback to run before all tests
   * @param {Function} callback - Callback function
   */
  beforeAll(callback) {
    this.beforeAllCallbacks.push(callback);
  }

  /**
   * Add callback to run after all tests
   * @param {Function} callback - Callback function
   */
  afterAll(callback) {
    this.afterAllCallbacks.push(callback);
  }

  /**
   * Run all tests in the suite
   * @returns {Promise<Object>} Test results
   */
  async run() {
    log(`🚀 Starting test suite: ${this.name}`, "info");
    if (this.description) {
      log(`   ${this.description}`, "info");
    }

    const results = {
      suiteName: this.name,
      passed: 0,
      failed: 0,
      total: this.tests.length,
      errors: [],
      startTime: Date.now(),
    };

    try {
      // Run beforeAll callbacks
      for (const callback of this.beforeAllCallbacks) {
        await callback();
      }

      // Run each test
      for (const test of this.tests) {
        try {
          startTest(`${this.name} - ${test.name}`);

          // Run beforeEach callbacks
          for (const callback of this.beforeEachCallbacks) {
            await callback();
          }

          // Run the test
          await test.testFn();
          results.passed++;

          // Run afterEach callbacks
          for (const callback of this.afterEachCallbacks) {
            await callback();
          }
        } catch (error) {
          results.failed++;
          results.errors.push({
            testName: test.name,
            error: error.message,
            stack: error.stack,
          });
          log(`Test failed: ${test.name} - ${error.message}`, "error");
        } finally {
          endTest();
        }
      }

      // Run afterAll callbacks
      for (const callback of this.afterAllCallbacks) {
        await callback();
      }
    } catch (error) {
      log(`Test suite setup/teardown failed: ${error.message}`, "error");
      results.errors.push({
        testName: "Suite Setup/Teardown",
        error: error.message,
        stack: error.stack,
      });
    }

    results.endTime = Date.now();
    results.duration = results.endTime - results.startTime;

    // Log results
    if (results.failed === 0) {
      log(
        `✅ Test suite passed: ${results.passed}/${results.total} tests`,
        "success"
      );
    } else {
      log(
        `❌ Test suite failed: ${results.failed}/${results.total} tests failed`,
        "error"
      );
    }

    return results;
  }
}

/**
 * Base TestFixtures class for managing test data for features
 */
export class TestFixtures {
  constructor(featureName) {
    this.featureName = featureName;
    this.createdRecords = new Map(); // table -> Set of IDs
    this.testPrefix = TEST_CONFIG.TEST_PREFIX;
  }

  /**
   * Track a created record for cleanup
   * @param {string} table - Table name
   * @param {string|number} id - Record ID
   */
  trackRecord(table, id) {
    if (!this.createdRecords.has(table)) {
      this.createdRecords.set(table, new Set());
    }
    this.createdRecords.get(table).add(id);
    log(`Tracking ${table} record: ${id}`, "debug");
  }

  /**
   * Untrack a record (e.g., after manual deletion)
   * @param {string} table - Table name
   * @param {string|number} id - Record ID
   */
  untrackRecord(table, id) {
    if (this.createdRecords.has(table)) {
      this.createdRecords.get(table).delete(id);
    }
  }

  /**
   * Get all tracked records for a table
   * @param {string} table - Table name
   * @returns {Set} Set of record IDs
   */
  getTrackedRecords(table) {
    return this.createdRecords.get(table) || new Set();
  }

  /**
   * Clean up all tracked records
   * @returns {Promise<number>} Number of records cleaned
   */
  async cleanup() {
    log(`🧹 Starting cleanup for ${this.featureName} fixtures...`, "info");

    let totalCleaned = 0;
    const tables = Array.from(this.createdRecords.keys());

    // Clean in reverse order (to handle dependencies)
    for (const table of tables.reverse()) {
      const recordIds = this.getTrackedRecords(table);
      if (recordIds.size === 0) continue;

      try {
        const { data, error } = await supabase
          .from(table)
          .delete()
          .in("id", Array.from(recordIds));

        if (error && error.code !== "PGRST116") {
          // PGRST116 = no rows found
          throw error;
        }

        const cleaned = data?.length || 0;
        totalCleaned += cleaned;

        if (cleaned > 0) {
          log(`Cleaned ${cleaned} records from ${table}`, "debug");
        }

        // Clear tracking for this table
        this.createdRecords.delete(table);
      } catch (error) {
        log(`Failed to clean ${table}: ${error.message}`, "error");
      }
    }

    log(
      `Cleanup completed for ${this.featureName}: ${totalCleaned} records removed`,
      "success"
    );
    return totalCleaned;
  }

  /**
   * Generate test name with feature prefix
   * @param {string} baseName - Base name for the test data
   * @returns {string} Test name with prefix and timestamp
   */
  generateTestName(baseName) {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(7);
    return `${this.testPrefix}${this.featureName}_${baseName}_${timestamp}_${random}`;
  }

  /**
   * Create a test record with automatic tracking
   * @param {string} table - Table name
   * @param {Object} data - Record data
   * @returns {Promise<Object>} Created record
   */
  async createRecord(table, data) {
    try {
      const { data: record, error } = await supabase
        .from(table)
        .insert(data)
        .select()
        .single();

      if (error) {
        throw error;
      }

      this.trackRecord(table, record.id);
      log(`Created ${table} record: ${record.id}`, "debug");
      return record;
    } catch (error) {
      log(`Failed to create ${table} record: ${error.message}`, "error");
      throw error;
    }
  }

  /**
   * Update a tracked record
   * @param {string} table - Table name
   * @param {string|number} id - Record ID
   * @param {Object} updates - Updates to apply
   * @returns {Promise<Object>} Updated record
   */
  async updateRecord(table, id, updates) {
    try {
      const { data: record, error } = await supabase
        .from(table)
        .update(updates)
        .eq("id", id)
        .select()
        .single();

      if (error) {
        throw error;
      }

      log(`Updated ${table} record: ${id}`, "debug");
      return record;
    } catch (error) {
      log(`Failed to update ${table} record ${id}: ${error.message}`, "error");
      throw error;
    }
  }
}
