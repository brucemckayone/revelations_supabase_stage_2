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
    this.recordDependencies = new Map(); // parent_table:parent_id -> Set of child_table:child_id
    this.testPrefix = TEST_CONFIG.TEST_PREFIX;
    this.cleanupInProgress = false;
  }

  /**
   * Track a created record for cleanup
   * @param {string} table - Table name
   * @param {string|number} id - Record ID
   * @param {Object} dependencies - Optional dependency information
   */
  trackRecord(table, id, dependencies = {}) {
    if (!this.createdRecords.has(table)) {
      this.createdRecords.set(table, new Set());
    }
    this.createdRecords.get(table).add(id);

    // Track dependencies for proper cleanup order
    if (dependencies.parentTable && dependencies.parentId) {
      const parentKey = `${dependencies.parentTable}:${dependencies.parentId}`;
      const childKey = `${table}:${id}`;

      if (!this.recordDependencies.has(parentKey)) {
        this.recordDependencies.set(parentKey, new Set());
      }
      this.recordDependencies.get(parentKey).add(childKey);
    }

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
   * Clean up all tracked records in proper dependency order
   * @returns {Promise<number>} Number of records cleaned
   */
  async cleanup() {
    if (this.cleanupInProgress) {
      log(`Cleanup already in progress for ${this.featureName}`, "warning");
      return 0;
    }

    this.cleanupInProgress = true;
    log(`🧹 Starting cleanup for ${this.featureName} fixtures...`, "info");

    let totalCleaned = 0;

    try {
      // First attempt: Smart dependency-aware cleanup
      totalCleaned = await this._smartCleanup();

      // Second attempt: Fallback cleanup for remaining records
      if (this.createdRecords.size > 0) {
        log(`Running fallback cleanup for remaining records...`, "info");
        totalCleaned += await this._fallbackCleanup();
      }
    } catch (error) {
      log(`Cleanup error: ${error.message}`, "error");
    } finally {
      this.cleanupInProgress = false;
    }

    log(
      `Cleanup completed for ${this.featureName}: ${totalCleaned} records removed`,
      totalCleaned > 0 ? "success" : "info"
    );
    return totalCleaned;
  }

  /**
   * Smart cleanup that respects dependencies and foreign key constraints
   */
  async _smartCleanup() {
    let totalCleaned = 0;

    // Define cleanup order based on common dependency patterns
    const cleanupOrder = [
      // Child records first (most dependent)
      "universal_package_event_usage",
      "event_bookings",
      "purchases",
      "universal_package_purchases",

      // Intermediate records
      "tickets",
      "event_dates",
      "post_tags",

      // Parent records (least dependent)
      "events",
      "universal_packages",
      "posts",
      "tags",
    ];

    // Clean up in dependency order
    for (const table of cleanupOrder) {
      if (!this.createdRecords.has(table)) continue;

      const recordIds = Array.from(this.getTrackedRecords(table));
      if (recordIds.length === 0) continue;

      totalCleaned += await this._cleanupTable(table, recordIds);
    }

    // Clean up any remaining tables not in our predefined order
    const remainingTables = Array.from(this.createdRecords.keys()).filter(
      (table) => !cleanupOrder.includes(table)
    );

    for (const table of remainingTables) {
      const recordIds = Array.from(this.getTrackedRecords(table));
      if (recordIds.length === 0) continue;

      totalCleaned += await this._cleanupTable(table, recordIds);
    }

    return totalCleaned;
  }

  /**
   * Fallback cleanup for records that couldn't be deleted due to constraints
   */
  async _fallbackCleanup() {
    let totalCleaned = 0;

    // Try to handle specific constraint violations
    for (const [table, recordIds] of this.createdRecords.entries()) {
      if (recordIds.size === 0) continue;

      try {
        if (table === "tickets" || table === "event_dates") {
          // These might fail due to existing purchases - try to clean purchases first
          await this._forceCleanPurchases(Array.from(recordIds), table);
        }

        // Try cleanup again
        totalCleaned += await this._cleanupTable(table, Array.from(recordIds));
      } catch (error) {
        log(
          `Fallback cleanup failed for ${table}: ${error.message}`,
          "warning"
        );
      }
    }

    return totalCleaned;
  }

  /**
   * Force clean purchases related to specific records
   */
  async _forceCleanPurchases(recordIds, parentTable) {
    try {
      if (parentTable === "tickets") {
        // Find and delete purchases for these tickets
        const { data: relatedBookings } = await supabase
          .from("event_bookings")
          .select("purchase_id")
          .in("ticket_id", recordIds);

        if (relatedBookings && relatedBookings.length > 0) {
          const purchaseIds = relatedBookings
            .map((b) => b.purchase_id)
            .filter(Boolean);

          if (purchaseIds.length > 0) {
            await supabase.from("purchases").delete().in("id", purchaseIds);
            log(
              `Force deleted ${purchaseIds.length} related purchases`,
              "debug"
            );
          }
        }
      } else if (parentTable === "event_dates") {
        // Find and delete purchases for these event dates
        const { data: relatedBookings } = await supabase
          .from("event_bookings")
          .select("purchase_id")
          .in("date_id", recordIds);

        if (relatedBookings && relatedBookings.length > 0) {
          const purchaseIds = relatedBookings
            .map((b) => b.purchase_id)
            .filter(Boolean);

          if (purchaseIds.length > 0) {
            await supabase.from("purchases").delete().in("id", purchaseIds);
            log(
              `Force deleted ${purchaseIds.length} related purchases`,
              "debug"
            );
          }
        }
      }
    } catch (error) {
      log(`Force cleanup of purchases failed: ${error.message}`, "warning");
    }
  }

  /**
   * Clean up a specific table with error handling
   */
  async _cleanupTable(table, recordIds) {
    if (!recordIds || recordIds.length === 0) return 0;

    try {
      const { data, error } = await supabase
        .from(table)
        .delete()
        .in("id", recordIds);

      if (error) {
        if (error.code === "PGRST116") {
          // No rows found - already deleted
          this.createdRecords.delete(table);
          return 0;
        }

        if (
          error.message.includes("violates foreign key constraint") ||
          error.message.includes("cannot delete") ||
          error.message.includes("already been purchased")
        ) {
          log(
            `Skipping ${table} due to constraint: ${error.message}`,
            "warning"
          );
          return 0;
        }

        throw error;
      }

      const cleaned = data?.length || 0;

      if (cleaned > 0) {
        log(`Cleaned ${cleaned} records from ${table}`, "debug");
        // Remove successfully cleaned records from tracking
        this.createdRecords.delete(table);
      }

      return cleaned;
    } catch (error) {
      log(`Failed to clean ${table}: ${error.message}`, "error");
      return 0;
    }
  }

  /**
   * Get cleanup status for debugging
   */
  getCleanupStatus() {
    const status = {
      featureName: this.featureName,
      totalTables: this.createdRecords.size,
      totalRecords: 0,
      tableBreakdown: {},
    };

    for (const [table, recordIds] of this.createdRecords.entries()) {
      const count = recordIds.size;
      status.tableBreakdown[table] = count;
      status.totalRecords += count;
    }

    return status;
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
