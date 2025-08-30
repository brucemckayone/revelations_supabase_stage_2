import { supabase } from "../../config/database.js";
import { log } from "./test-utils.js";

/**
 * Centralized cleanup coordinator for handling complex cleanup scenarios
 * across multiple test features with shared dependencies
 */
export class CleanupCoordinator {
  constructor() {
    this.activeFixtures = new Set();
    this.globalCleanupInProgress = false;
  }

  /**
   * Register a fixture for global cleanup coordination
   */
  registerFixture(fixture) {
    this.activeFixtures.add(fixture);
    log(`Registered fixture: ${fixture.featureName}`, "debug");
  }

  /**
   * Unregister a fixture
   */
  unregisterFixture(fixture) {
    this.activeFixtures.delete(fixture);
    log(`Unregistered fixture: ${fixture.featureName}`, "debug");
  }

  /**
   * Force cleanup all test data from the last N hours
   * Use with caution - this is for emergency cleanup scenarios
   */
  async emergencyCleanup(hoursBack = 2) {
    if (this.globalCleanupInProgress) {
      log("Emergency cleanup already in progress", "warning");
      return false;
    }

    this.globalCleanupInProgress = true;
    log(`🚨 Starting emergency cleanup for last ${hoursBack} hours...`, "info");

    try {
      const cutoffTime = new Date(
        Date.now() - hoursBack * 60 * 60 * 1000
      ).toISOString();
      let totalCleaned = 0;

      // Clean up in dependency order
      const cleanupOperations = [
        () =>
          this._emergencyCleanTable(
            "universal_package_event_usage",
            cutoffTime
          ),
        () => this._emergencyCleanTable("event_bookings", cutoffTime),
        () => this._emergencyCleanTable("purchases", cutoffTime),
        () =>
          this._emergencyCleanTable("universal_package_purchases", cutoffTime),
        () => this._emergencyCleanTable("tickets", cutoffTime),
        () => this._emergencyCleanTable("event_dates", cutoffTime),
        () => this._emergencyCleanTable("events", cutoffTime),
        () => this._emergencyCleanTable("universal_packages", cutoffTime),
        () => this._emergencyCleanTable("post_tags", cutoffTime),
        () => this._emergencyCleanTable("posts", cutoffTime),
        () => this._emergencyCleanTestTags(),
      ];

      for (const operation of cleanupOperations) {
        try {
          const cleaned = await operation();
          totalCleaned += cleaned;
        } catch (error) {
          log(
            `Emergency cleanup operation failed: ${error.message}`,
            "warning"
          );
        }
      }

      log(
        `🗑️ Emergency cleanup completed: ${totalCleaned} records removed`,
        "success"
      );
      return true;
    } catch (error) {
      log(`❌ Emergency cleanup failed: ${error.message}`, "error");
      return false;
    } finally {
      this.globalCleanupInProgress = false;
    }
  }

  /**
   * Clean up specific table with time-based filters
   */
  async _emergencyCleanTable(tableName, cutoffTime) {
    try {
      let query = supabase.from(tableName).delete();

      // Apply different cleanup strategies based on table
      if (tableName === "posts") {
        query = query.or(`title.like.TEST_%,created_at.gte.${cutoffTime}`);
      } else if (tableName === "universal_packages") {
        query = query.or(`name.like.TEST_%,created_at.gte.${cutoffTime}`);
      } else if (tableName === "tickets") {
        query = query.or(`title.like.TEST_%,created_at.gte.${cutoffTime}`);
      } else if (tableName === "event_bookings") {
        query = query.or(
          `ticket_code.like.TEST-%,created_at.gte.${cutoffTime}`
        );
      } else if (tableName === "purchases") {
        // Clean test purchases or recent purchases that might be test-related
        query = query.or(
          `metadata->>'test_purchase'.eq.true,created_at.gte.${cutoffTime},purchase_type.eq.event,purchase_type.eq.universal_package`
        );
      } else {
        // For other tables, use time-based cleanup only
        query = query.gte("created_at", cutoffTime);
      }

      const { data, error } = await query;

      if (error && error.code !== "PGRST116") {
        // Ignore constraint violations during emergency cleanup
        if (
          error.message.includes("violates foreign key constraint") ||
          error.message.includes("cannot delete") ||
          error.message.includes("already been purchased")
        ) {
          log(
            `Skipping ${tableName} due to constraint during emergency cleanup`,
            "debug"
          );
          return 0;
        }
        throw error;
      }

      const cleaned = data?.length || 0;
      if (cleaned > 0) {
        log(`Emergency cleaned ${cleaned} records from ${tableName}`, "debug");
      }
      return cleaned;
    } catch (error) {
      log(
        `Failed to emergency clean ${tableName}: ${error.message}`,
        "warning"
      );
      return 0;
    }
  }

  /**
   * Clean up test tags
   */
  async _emergencyCleanTestTags() {
    try {
      const { data, error } = await supabase
        .from("tags")
        .delete()
        .or(
          "name.like.TEST_%,name.eq.test,name.eq.automation,name.eq.integration,name.eq.multiple,name.eq.updated"
        );

      if (error && error.code !== "PGRST116") {
        throw error;
      }

      const cleaned = data?.length || 0;
      if (cleaned > 0) {
        log(`Emergency cleaned ${cleaned} test tags`, "debug");
      }
      return cleaned;
    } catch (error) {
      log(`Failed to emergency clean test tags: ${error.message}`, "warning");
      return 0;
    }
  }

  /**
   * Perform coordinated cleanup across all registered fixtures
   */
  async coordinatedCleanup() {
    if (this.globalCleanupInProgress) {
      log("Coordinated cleanup already in progress", "warning");
      return 0;
    }

    this.globalCleanupInProgress = true;
    log("🧹 Starting coordinated cleanup across all fixtures...", "info");

    let totalCleaned = 0;

    try {
      // Clean up each fixture
      for (const fixture of this.activeFixtures) {
        try {
          const cleaned = await fixture.cleanup();
          totalCleaned += cleaned;
        } catch (error) {
          log(
            `Fixture cleanup failed for ${fixture.featureName}: ${error.message}`,
            "warning"
          );
        }
      }

      // Run emergency cleanup for any remaining test data
      if (totalCleaned === 0) {
        log(
          "No records cleaned by fixtures, running emergency cleanup...",
          "info"
        );
        await this.emergencyCleanup(1); // Clean last hour
      }
    } finally {
      this.globalCleanupInProgress = false;
    }

    log(
      `🗑️ Coordinated cleanup completed: ${totalCleaned} records removed`,
      "success"
    );
    return totalCleaned;
  }

  /**
   * Verify that all test data has been properly cleaned
   */
  async verifyCleanup() {
    log("🔍 Verifying cleanup completion...", "info");

    const testDataQueries = [
      { table: "posts", condition: "title.like.TEST_%" },
      {
        table: "events",
        condition:
          "created_at.gte." +
          new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
      },
      { table: "event_bookings", condition: "ticket_code.like.TEST-%" },
      { table: "universal_packages", condition: "name.like.TEST_%" },
      { table: "purchases", condition: "metadata->>'test_purchase'.eq.true" },
    ];

    let hasRemainingData = false;

    for (const { table, condition } of testDataQueries) {
      try {
        const parts = condition.split(".");
        let query = supabase.from(table).select("id").limit(1);

        if (parts[1] === "like") {
          query = query.like(parts[0], parts[2]);
        } else if (parts[1] === "gte") {
          query = query.gte(parts[0], parts[2]);
        } else if (parts[1] === "eq") {
          // Handle JSON operator
          if (parts[0].includes("->")) {
            query = query.or(condition);
          } else {
            query = query.eq(parts[0], parts[2]);
          }
        }

        const { data, error } = await query;

        if (error) {
          log(
            `Verification query failed for ${table}: ${error.message}`,
            "warning"
          );
          continue;
        }

        if (data && data.length > 0) {
          log(`❌ Found remaining test data in ${table}`, "warning");
          hasRemainingData = true;
        }
      } catch (error) {
        log(`Verification failed for ${table}: ${error.message}`, "warning");
      }
    }

    if (!hasRemainingData) {
      log("✅ Cleanup verification passed - no test data remaining", "success");
    } else {
      log("⚠️ Cleanup verification found remaining test data", "warning");
    }

    return !hasRemainingData;
  }
}

// Global coordinator instance
export const globalCleanupCoordinator = new CleanupCoordinator();

