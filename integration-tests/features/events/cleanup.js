import { supabase } from "../../config/database.js";

/**
 * Main cleanup function for all event-related test data
 */
export async function cleanup() {
  console.log("🧹 Cleaning up events test data...");

  const cleanupTasks = [
    // Clean up in dependency order (children first, then parents)
    () => cleanupTable("universal_package_event_usage", "package_purchase_id"),
    () => cleanupTable("event_bookings", "ticket_code"),
    () => cleanupEventPurchases(), // Updated to handle new purchasing system
    () => cleanupTable("universal_package_purchases", "id"),
    () => cleanupTable("universal_packages", "name"),
    () => cleanupTable("tickets", "title"),
    () => cleanupTable("event_dates", "id"),
    () => cleanupTable("events", "id"),
    () => cleanupTable("post_tags", "post_id"),
    () => cleanupTable("posts", "title"),
    () => cleanupTestTags(),
  ];

  let totalCleaned = 0;
  for (const task of cleanupTasks) {
    try {
      const cleaned = await task();
      totalCleaned += cleaned;
    } catch (error) {
      console.error(`Cleanup task failed: ${error.message}`);
    }
  }

  console.log(`🗑️ Cleaned up ${totalCleaned} event test records`);
  return totalCleaned;
}

/**
 * Cleanup event purchases using the new purchasing system
 * This replaces the old cleanupPurchases function to work with the new schema
 */
async function cleanupEventPurchases() {
  let totalCleaned = 0;

  try {
    // First, find all test-related event bookings
    const { data: testEventBookings } = await supabase
      .from("event_bookings")
      .select("purchase_id")
      .like("ticket_code", "TEST-%");

    if (testEventBookings && testEventBookings.length > 0) {
      const purchaseIds = testEventBookings.map(
        (booking) => booking.purchase_id
      );

      // Clean up the purchases linked to test event bookings
      const { data: deletedPurchases, error: purchaseError } = await supabase
        .from("purchases")
        .delete()
        .in("id", purchaseIds);

      if (purchaseError && purchaseError.code !== "PGRST116") {
        throw purchaseError;
      }

      totalCleaned += deletedPurchases?.length || 0;
    }

    // Also clean up purchases that are clearly test-related by metadata or type
    const { data: testPurchases, error: testPurchaseError } = await supabase
      .from("purchases")
      .delete()
      .or(
        `metadata->>'test_purchase'.eq.true,purchase_type.eq.event,purchase_type.eq.universal_package,stripe_payment_intent_id.like.test_%`
      );

    if (testPurchaseError && testPurchaseError.code !== "PGRST116") {
      throw testPurchaseError;
    }

    totalCleaned += testPurchases?.length || 0;
  } catch (error) {
    console.warn(`Warning cleaning event purchases: ${error.message}`);
  }

  if (totalCleaned > 0) {
    console.log(`  🗑️ Cleaned ${totalCleaned} event purchase records`);
  }
  return totalCleaned;
}

/**
 * Cleanup test tags
 */
async function cleanupTestTags() {
  const { data, error } = await supabase
    .from("tags")
    .delete()
    .or(
      "name.like.TEST_%,name.eq.test,name.eq.automation,name.eq.integration,name.eq.multiple,name.eq.updated"
    );

  if (error && error.code !== "PGRST116") {
    throw error;
  }

  return data?.length || 0;
}

/**
 * Generic cleanup function for tables
 */
async function cleanupTable(tableName, column = "name") {
  let query = supabase.from(tableName).delete();

  // Use different patterns based on the column type
  if (column === "name" || column === "title") {
    query = query.like(column, "TEST_%");
  } else if (column === "ticket_code") {
    query = query.like(column, "TEST-%");
  } else if (column === "id") {
    // For tables without a name/title column, we need to find test records differently
    // First, get IDs of test records by joining with related tables
    if (tableName === "event_dates") {
      // Get test event IDs by finding events linked to test posts
      const { data: testPosts } = await supabase
        .from("posts")
        .select("id")
        .like("title", "TEST_%");

      if (!testPosts || testPosts.length === 0) {
        return 0;
      }

      const { data: eventIds } = await supabase
        .from("events")
        .select("id")
        .in(
          "post_id",
          testPosts.map((p) => p.id)
        );

      if (eventIds && eventIds.length > 0) {
        query = query.in(
          "event_id",
          eventIds.map((e) => e.id)
        );
      } else {
        return 0; // No test events to clean up dates for
      }
    } else if (tableName === "events") {
      const { data: postIds } = await supabase
        .from("posts")
        .select("id")
        .like("title", "TEST_%");

      if (postIds && postIds.length > 0) {
        query = query.in(
          "post_id",
          postIds.map((p) => p.id)
        );
      } else {
        return 0; // No test posts to clean up events for
      }
    } else if (tableName === "tickets") {
      // Clean up tickets by finding events linked to test posts
      const { data: testPosts } = await supabase
        .from("posts")
        .select("id")
        .like("title", "TEST_%");

      if (!testPosts || testPosts.length === 0) {
        return 0;
      }

      const { data: eventIds } = await supabase
        .from("events")
        .select("id")
        .in(
          "post_id",
          testPosts.map((p) => p.id)
        );

      if (eventIds && eventIds.length > 0) {
        query = query.in(
          "event_id",
          eventIds.map((e) => e.id)
        );
      } else {
        return 0;
      }
    } else if (tableName === "event_bookings") {
      // Clean up event bookings with test ticket codes
      query = query.like("ticket_code", "TEST-%");
    } else if (tableName === "universal_package_purchases") {
      // Clean up by finding purchases associated with test packages
      const { data: testPackages } = await supabase
        .from("universal_packages")
        .select("id")
        .like("name", "TEST_%");

      if (!testPackages || testPackages.length === 0) {
        return 0;
      }

      const { data: packagePurchases } = await supabase
        .from("universal_package_purchases")
        .select("id")
        .in(
          "package_id",
          testPackages.map((p) => p.id)
        );

      if (!packagePurchases || packagePurchases.length === 0) {
        return 0;
      }

      query = query.in(
        "id",
        packagePurchases.map((p) => p.id)
      );
    } else if (tableName === "universal_package_event_usage") {
      // Clean up by finding usage associated with test package purchases
      const { data: testPackages } = await supabase
        .from("universal_packages")
        .select("id")
        .like("name", "TEST_%");

      if (!testPackages || testPackages.length === 0) {
        return 0;
      }

      const { data: packagePurchases } = await supabase
        .from("universal_package_purchases")
        .select("id")
        .in(
          "package_id",
          testPackages.map((p) => p.id)
        );

      if (packagePurchases && packagePurchases.length > 0) {
        query = query.in(
          "package_purchase_id",
          packagePurchases.map((p) => p.id)
        );
      } else {
        return 0;
      }
    } else if (tableName === "post_tags") {
      // Clean up post_tags by finding posts with TEST_ titles
      const { data: postIds } = await supabase
        .from("posts")
        .select("id")
        .like("title", "TEST_%");

      if (postIds && postIds.length > 0) {
        query = query.in(
          "post_id",
          postIds.map((p) => p.id)
        );
      } else {
        return 0;
      }
    } else {
      // Default fallback - skip if we don't know how to handle this table
      console.warn(`No cleanup strategy for table: ${tableName}`);
      return 0;
    }
  }

  const { data, error } = await query;

  if (error && error.code !== "PGRST116") {
    // Ignore "no rows found"
    console.warn(`Warning cleaning ${tableName}: ${error.message}`);
    return 0;
  }

  const count = data?.length || 0;
  if (count > 0) {
    console.log(`  🗑️ Cleaned ${count} records from ${tableName}`);
  }
  return count;
}

/**
 * Verify that all test data has been cleaned up
 */
export async function verify() {
  console.log("🔍 Verifying events cleanup...");

  const tablesToCheck = [
    { table: "posts", column: "title", pattern: "TEST_%" },
    { table: "events", column: "id", joinCheck: "posts" },
    { table: "event_dates", column: "id", joinCheck: "events" },
    { table: "tickets", column: "title", pattern: "TEST_%" },
    { table: "event_bookings", column: "ticket_code", pattern: "TEST-%" },
    { table: "purchases", column: "purchase_type", pattern: "event" }, // Updated for new system
    { table: "universal_packages", column: "name", pattern: "TEST_%" },
    {
      table: "universal_package_purchases",
      column: "id",
      joinCheck: "universal_packages",
    },
  ];

  for (const { table, column, pattern, joinCheck } of tablesToCheck) {
    let query = supabase.from(table).select("id").limit(1);

    if (pattern) {
      if (table === "purchases" && column === "purchase_type") {
        // Special check for event purchases
        query = query.or(
          "purchase_type.eq.event,metadata->>'test_purchase'.eq.true"
        );
      } else {
        query = query.like(column, pattern);
      }
    } else if (joinCheck) {
      // For tables without direct patterns, check if any remain via joins
      if (table === "events" && joinCheck === "posts") {
        const { data: testPostIds } = await supabase
          .from("posts")
          .select("id")
          .like("title", "TEST_%")
          .limit(1);

        if (!testPostIds || testPostIds.length === 0) continue;
        query = query.in(
          "post_id",
          testPostIds.map((p) => p.id)
        );
      } else if (table === "event_dates" && joinCheck === "events") {
        const { data: testPosts } = await supabase
          .from("posts")
          .select("id")
          .like("title", "TEST_%")
          .limit(1);

        if (!testPosts || testPosts.length === 0) continue;

        const { data: testEventIds } = await supabase
          .from("events")
          .select("id")
          .in(
            "post_id",
            testPosts.map((p) => p.id)
          )
          .limit(1);

        if (!testEventIds || testEventIds.length === 0) continue;
        query = query.in(
          "event_id",
          testEventIds.map((e) => e.id)
        );
      } else if (
        table === "universal_package_purchases" &&
        joinCheck === "universal_packages"
      ) {
        const { data: testPackageIds } = await supabase
          .from("universal_packages")
          .select("id")
          .like("name", "TEST_%")
          .limit(1);

        if (!testPackageIds || testPackageIds.length === 0) continue;
        query = query.in(
          "package_id",
          testPackageIds.map((p) => p.id)
        );
      }
    }

    const { data, error } = await query;

    if (error) {
      console.warn(`Warning checking ${table}: ${error.message}`);
      continue;
    }

    if (data && data.length > 0) {
      console.log(`❌ Found remaining test data in ${table}`);
      return false;
    }
  }

  console.log("✅ Events cleanup verification passed");
  return true;
}

/**
 * Emergency cleanup function for when normal cleanup fails
 */
export async function forceCleanup() {
  console.log("🚨 Force cleaning all events test data...");

  try {
    // Delete all event bookings with test ticket codes
    await supabase
      .from("event_bookings")
      .delete()
      .like("ticket_code", "TEST-%");

    // Delete all purchases from the last 2 hours that might be test-related
    const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString();

    await supabase
      .from("purchases")
      .delete()
      .or(
        `created_at.gte.${twoHoursAgo},purchase_type.eq.event,purchase_type.eq.universal_package,metadata->>'test_purchase'.eq.true`
      );

    // Delete all posts with TEST_ prefix or created in the last 2 hours
    await supabase
      .from("posts")
      .delete()
      .or(`title.like.TEST_%,created_at.gte.${twoHoursAgo}`);

    // Delete all universal packages with TEST_ prefix
    await supabase.from("universal_packages").delete().like("name", "TEST_%");

    console.log("🗑️ Force cleanup completed");
    return true;
  } catch (error) {
    console.error("❌ Force cleanup failed:", error.message);
    return false;
  }
}
