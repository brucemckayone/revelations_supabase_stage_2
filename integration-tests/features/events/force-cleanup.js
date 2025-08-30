import { supabase } from "../../config/database.js";
import { log } from "../../shared/utilities/test-utils.js";

/**
 * Force cleanup utility for events system
 * This handles the complex dependency chains that prevent normal cleanup
 */
export class EventsForceCleanup {
  
  /**
   * Perform aggressive cleanup of all test data
   */
  static async forceCleanAllTestData(hoursBack = 2) {
    log("🚨 Starting force cleanup of all test data...", "info");
    
    const cutoffTime = new Date(Date.now() - hoursBack * 60 * 60 * 1000).toISOString();
    let totalCleaned = 0;

    try {
      // Step 1: Clean universal package event usage
      totalCleaned += await this._forceCleanTable(
        "universal_package_event_usage",
        `created_at.gte.${cutoffTime}`
      );

      // Step 2: Clean event bookings (this is often the blocker)
      totalCleaned += await this._forceCleanEventBookings(cutoffTime);

      // Step 3: Clean purchases that are test-related
      totalCleaned += await this._forceCleanPurchases(cutoffTime);

      // Step 4: Clean universal package purchases
      totalCleaned += await this._forceCleanUniversalPackagePurchases(cutoffTime);

      // Step 5: Clean tickets (should work now that bookings are gone)
      totalCleaned += await this._forceCleanTickets(cutoffTime);

      // Step 6: Clean event dates (should work now that bookings are gone)
      totalCleaned += await this._forceCleanEventDates(cutoffTime);

      // Step 7: Clean events
      totalCleaned += await this._forceCleanEvents(cutoffTime);

      // Step 8: Clean universal packages
      totalCleaned += await this._forceCleanUniversalPackages();

      // Step 9: Clean post tags
      totalCleaned += await this._forceCleanPostTags(cutoffTime);

      // Step 10: Clean posts
      totalCleaned += await this._forceCleanPosts();

      // Step 11: Clean test tags
      totalCleaned += await this._forceCleanTestTags();

      log(`🗑️ Force cleanup completed: ${totalCleaned} records removed`, "success");
      
      // Additional logging to help debug
      if (totalCleaned === 0) {
        log("No records were cleaned. Checking if test data exists...", "info");
        await this._debugRemainingData();
      }
      
      return totalCleaned;
    } catch (error) {
      log(`❌ Force cleanup failed: ${error.message}`, "error");
      return totalCleaned;
    }
  }

  /**
   * Debug what test data still remains
   */
  static async _debugRemainingData() {
    const tables = ['events', 'tickets', 'event_dates', 'posts'];
    
    for (const table of tables) {
      try {
        let query = supabase.from(table).select('id').limit(5);
        
        if (table === 'posts') {
          query = query.like('title', 'TEST_%');
        } else if (table === 'tickets') {
          query = query.like('title', 'TEST_%');
        }
        
        const { data, count } = await query;
        
        if (data && data.length > 0) {
          log(`Remaining ${table}: ${data.length} records`, "debug");
          data.forEach(record => {
            log(`  - ${record.id}`, "debug");
          });
        }
      } catch (error) {
        // Table doesn't exist or other error
      }
    }
  }

  /**
   * Force clean event bookings (the main blocker)
   */
  static async _forceCleanEventBookings(cutoffTime) {
    try {
      // First approach: Delete test bookings by ticket code pattern
      let { data: deletedByCode, error: codeError } = await supabase
        .from("event_bookings")
        .delete()
        .like("ticket_code", "TEST-%");

      if (codeError && !codeError.message.includes("no rows")) {
        log(`Warning cleaning bookings by code: ${codeError.message}`, "warning");
      }

      // Second approach: Delete recent bookings that might be test-related
      let { data: deletedByTime, error: timeError } = await supabase
        .from("event_bookings")
        .delete()
        .gte("created_at", cutoffTime);

      if (timeError && !timeError.message.includes("no rows")) {
        log(`Warning cleaning bookings by time: ${timeError.message}`, "warning");
      }

      const totalDeleted = (deletedByCode?.length || 0) + (deletedByTime?.length || 0);
      if (totalDeleted > 0) {
        log(`Force deleted ${totalDeleted} event bookings`, "debug");
      }
      return totalDeleted;
    } catch (error) {
      log(`Failed to force clean event bookings: ${error.message}`, "warning");
      return 0;
    }
  }

  /**
   * Force clean purchases with multiple strategies
   */
  static async _forceCleanPurchases(cutoffTime) {
    try {
      let totalDeleted = 0;

      // Strategy 1: Delete purchases marked as test
      const { data: testPurchases, error: testError } = await supabase
        .from("purchases")
        .delete()
        .eq("metadata->>'test_purchase'", "true");

      if (!testError) {
        totalDeleted += testPurchases?.length || 0;
      }

      // Strategy 2: Delete event-type purchases from recent time
      const { data: eventPurchases, error: eventError } = await supabase
        .from("purchases")
        .delete()
        .eq("purchase_type", "event")
        .gte("created_at", cutoffTime);

      if (!eventError) {
        totalDeleted += eventPurchases?.length || 0;
      }

      // Strategy 3: Delete purchases with test payment intents
      const { data: testPayments, error: paymentError } = await supabase
        .from("purchases")
        .delete()
        .like("stripe_payment_intent_id", "pi_test_%");

      if (!paymentError) {
        totalDeleted += testPayments?.length || 0;
      }

      if (totalDeleted > 0) {
        log(`Force deleted ${totalDeleted} purchases`, "debug");
      }
      return totalDeleted;
    } catch (error) {
      log(`Failed to force clean purchases: ${error.message}`, "warning");
      return 0;
    }
  }

  /**
   * Force clean universal package purchases
   */
  static async _forceCleanUniversalPackagePurchases(cutoffTime) {
    try {
      // Find test packages first
      const { data: testPackages } = await supabase
        .from("universal_packages")
        .select("id")
        .like("name", "TEST_%");

      if (!testPackages || testPackages.length === 0) {
        return 0;
      }

      const packageIds = testPackages.map(p => p.id);

      // Delete package purchases for test packages
      const { data: deleted, error } = await supabase
        .from("universal_package_purchases")
        .delete()
        .in("package_id", packageIds);

      if (error && !error.message.includes("no rows")) {
        log(`Warning cleaning universal package purchases: ${error.message}`, "warning");
        return 0;
      }

      const totalDeleted = deleted?.length || 0;
      if (totalDeleted > 0) {
        log(`Force deleted ${totalDeleted} universal package purchases`, "debug");
      }
      return totalDeleted;
    } catch (error) {
      log(`Failed to force clean universal package purchases: ${error.message}`, "warning");
      return 0;
    }
  }

  /**
   * Force clean tickets
   */
  static async _forceCleanTickets(cutoffTime) {
    try {
      // Now that bookings should be gone, try to delete test tickets
      const { data: deleted, error } = await supabase
        .from("tickets")
        .delete()
        .like("title", "TEST_%");

      if (error && !error.message.includes("no rows")) {
        log(`Warning cleaning tickets: ${error.message}`, "warning");
        return 0;
      }

      const totalDeleted = deleted?.length || 0;
      if (totalDeleted > 0) {
        log(`Force deleted ${totalDeleted} tickets`, "debug");
      }
      return totalDeleted;
    } catch (error) {
      log(`Failed to force clean tickets: ${error.message}`, "warning");
      return 0;
    }
  }

  /**
   * Force clean event dates
   */
  static async _forceCleanEventDates(cutoffTime) {
    try {
      // Find test events first
      const { data: testPosts } = await supabase
        .from("posts")
        .select("id")
        .like("title", "TEST_%");

      if (!testPosts || testPosts.length === 0) {
        return 0;
      }

      const { data: testEvents } = await supabase
        .from("events")
        .select("id")
        .in("post_id", testPosts.map(p => p.id));

      if (!testEvents || testEvents.length === 0) {
        return 0;
      }

      // Delete event dates for test events
      const { data: deleted, error } = await supabase
        .from("event_dates")
        .delete()
        .in("event_id", testEvents.map(e => e.id));

      if (error && !error.message.includes("no rows")) {
        log(`Warning cleaning event dates: ${error.message}`, "warning");
        return 0;
      }

      const totalDeleted = deleted?.length || 0;
      if (totalDeleted > 0) {
        log(`Force deleted ${totalDeleted} event dates`, "debug");
      }
      return totalDeleted;
    } catch (error) {
      log(`Failed to force clean event dates: ${error.message}`, "warning");
      return 0;
    }
  }

  /**
   * Force clean events
   */
  static async _forceCleanEvents(cutoffTime) {
    return await this._forceCleanTable("events", null, cutoffTime);
  }

  /**
   * Force clean universal packages
   */
  static async _forceCleanUniversalPackages() {
    return await this._forceCleanTable("universal_packages", "name.like.TEST_%");
  }

  /**
   * Force clean post tags
   */
  static async _forceCleanPostTags(cutoffTime) {
    try {
      // Find test posts
      const { data: testPosts } = await supabase
        .from("posts")
        .select("id")
        .like("title", "TEST_%");

      if (!testPosts || testPosts.length === 0) {
        return 0;
      }

      // Delete post tags for test posts
      const { data: deleted, error } = await supabase
        .from("post_tags")
        .delete()
        .in("post_id", testPosts.map(p => p.id));

      if (error && !error.message.includes("no rows")) {
        log(`Warning cleaning post tags: ${error.message}`, "warning");
        return 0;
      }

      const totalDeleted = deleted?.length || 0;
      if (totalDeleted > 0) {
        log(`Force deleted ${totalDeleted} post tags`, "debug");
      }
      return totalDeleted;
    } catch (error) {
      log(`Failed to force clean post tags: ${error.message}`, "warning");
      return 0;
    }
  }

  /**
   * Force clean posts
   */
  static async _forceCleanPosts() {
    return await this._forceCleanTable("posts", "title.like.TEST_%");
  }

  /**
   * Force clean test tags
   */
  static async _forceCleanTestTags() {
    try {
      const { data: deleted, error } = await supabase
        .from("tags")
        .delete()
        .or(
          "name.like.TEST_%,name.eq.test,name.eq.automation,name.eq.integration,name.eq.multiple,name.eq.updated"
        );

      if (error && !error.message.includes("no rows")) {
        log(`Warning cleaning test tags: ${error.message}`, "warning");
        return 0;
      }

      const totalDeleted = deleted?.length || 0;
      if (totalDeleted > 0) {
        log(`Force deleted ${totalDeleted} test tags`, "debug");
      }
      return totalDeleted;
    } catch (error) {
      log(`Failed to force clean test tags: ${error.message}`, "warning");
      return 0;
    }
  }

  /**
   * Generic force clean table method
   */
  static async _forceCleanTable(tableName, condition = null, cutoffTime = null) {
    try {
      let query = supabase.from(tableName).delete();

      if (condition) {
        // Parse the condition
        if (condition.includes(".like.")) {
          const [field, value] = condition.split(".like.");
          query = query.like(field, value);
        } else if (condition.includes(".eq.")) {
          const [field, value] = condition.split(".eq.");
          query = query.eq(field, value);
        } else if (condition.includes(".gte.")) {
          const [field, value] = condition.split(".gte.");
          query = query.gte(field, value);
        }
      } else if (cutoffTime) {
        // Default to time-based cleanup for events and related tables
        if (tableName === "events") {
          // For events, find by test posts
          const { data: testPosts } = await supabase
            .from("posts")
            .select("id")
            .like("title", "TEST_%");

          if (!testPosts || testPosts.length === 0) {
            return 0;
          }

          query = query.in("post_id", testPosts.map(p => p.id));
        } else {
          query = query.gte("created_at", cutoffTime);
        }
      }

      const { data: deleted, error } = await query;

      if (error && !error.message.includes("no rows")) {
        log(`Warning cleaning ${tableName}: ${error.message}`, "warning");
        return 0;
      }

      const totalDeleted = deleted?.length || 0;
      if (totalDeleted > 0) {
        log(`Force deleted ${totalDeleted} records from ${tableName}`, "debug");
      }
      return totalDeleted;
    } catch (error) {
      log(`Failed to force clean ${tableName}: ${error.message}`, "warning");
      return 0;
    }
  }
}
