// Universal Packages Feature - Cleanup Logic

import { supabase, TEST_CONFIG } from "../../config/database.js";
import { log } from "../../shared/utilities/test-utils.js";

/**
 * Clean up all test data created by the universal packages feature
 * Cleans in dependency order: usage -> purchases -> packages -> events -> event_dates
 * @returns {Promise<number>} Number of records cleaned
 */
export async function cleanup() {
  log("🧹 Starting universal packages cleanup...", "info");

  const cleanupTasks = [
    cleanupPackageEventUsage, // Clean usage records first
    cleanupPackagePurchases, // Then purchases
    cleanupPackages, // Then packages themselves
    cleanupEventDates, // Then event dates
    cleanupEvents, // Finally events
  ];

  let totalCleaned = 0;

  for (const task of cleanupTasks) {
    try {
      const count = await task();
      totalCleaned += count;
    } catch (error) {
      log(`Universal packages cleanup task failed: ${error.message}`, "error");
    }
  }

  log(
    `Universal packages cleanup completed: ${totalCleaned} records removed`,
    "success"
  );
  return totalCleaned;
}

/**
 * Verify that cleanup was successful
 * @returns {Promise<boolean>} True if cleanup was complete
 */
export async function verify() {
  try {
    // Check for any remaining test records
    const checks = [
      { table: "universal_package_event_usage", field: "created_at" },
      { table: "universal_package_purchases", field: "created_at" },
      { table: "universal_packages", field: "name" },
      { table: "event_dates", field: "created_at" },
      { table: "events", field: "title" },
    ];

    for (const check of checks) {
      const { data, error } = await supabase
        .from(check.table)
        .select("id")
        .like(check.field, `%${TEST_CONFIG.TEST_PREFIX}%`)
        .limit(1);

      if (error) {
        log(
          `Verification check failed for ${check.table}: ${error.message}`,
          "warning"
        );
        return false;
      }

      if (data && data.length > 0) {
        log(
          `Verification failed: Found remaining test data in ${check.table}`,
          "warning"
        );
        return false;
      }
    }

    log("Universal packages cleanup verification passed", "success");
    return true;
  } catch (error) {
    log(
      `Universal packages cleanup verification failed: ${error.message}`,
      "error"
    );
    return false;
  }
}

// Individual cleanup functions

async function cleanupPackageEventUsage() {
  // Clean up usage records that reference test packages
  const { data: testUsage, error: usageError } = await supabase
    .from("universal_package_event_usage")
    .select("id")
    .in(
      "universal_package_purchase_id",
      supabase
        .from("universal_package_purchases")
        .select("id")
        .in(
          "universal_package_id",
          supabase
            .from("universal_packages")
            .select("id")
            .like("name", `${TEST_CONFIG.TEST_PREFIX}%`)
        )
    );

  if (usageError && usageError.code !== "PGRST116") {
    throw usageError;
  }

  if (testUsage && testUsage.length > 0) {
    const { error: deleteError } = await supabase
      .from("universal_package_event_usage")
      .delete()
      .in(
        "id",
        testUsage.map((u) => u.id)
      );

    if (deleteError) {
      throw deleteError;
    }

    log(`Cleaned up ${testUsage.length} package usage records`, "debug");
    return testUsage.length;
  }

  return 0;
}

async function cleanupPackagePurchases() {
  // Clean up purchases that reference test packages
  const { data: testPurchases, error: purchaseError } = await supabase
    .from("universal_package_purchases")
    .select("id")
    .in(
      "universal_package_id",
      supabase
        .from("universal_packages")
        .select("id")
        .like("name", `${TEST_CONFIG.TEST_PREFIX}%`)
    );

  if (purchaseError && purchaseError.code !== "PGRST116") {
    throw purchaseError;
  }

  if (testPurchases && testPurchases.length > 0) {
    const { error: deleteError } = await supabase
      .from("universal_package_purchases")
      .delete()
      .in(
        "id",
        testPurchases.map((p) => p.id)
      );

    if (deleteError) {
      throw deleteError;
    }

    log(`Cleaned up ${testPurchases.length} package purchases`, "debug");
    return testPurchases.length;
  }

  return 0;
}

async function cleanupPackages() {
  const { data, error } = await supabase
    .from("universal_packages")
    .delete()
    .like("name", `${TEST_CONFIG.TEST_PREFIX}%`);

  if (error && error.code !== "PGRST116") {
    throw error;
  }

  const count = data?.length || 0;
  if (count > 0) {
    log(`Cleaned up ${count} universal packages`, "debug");
  }
  return count;
}

async function cleanupEventDates() {
  // Clean up event dates for test events
  const { data: testDates, error: datesError } = await supabase
    .from("event_dates")
    .select("id")
    .in(
      "event_id",
      supabase
        .from("events")
        .select("id")
        .like("title", `${TEST_CONFIG.TEST_PREFIX}%`)
    );

  if (datesError && datesError.code !== "PGRST116") {
    throw datesError;
  }

  if (testDates && testDates.length > 0) {
    const { error: deleteError } = await supabase
      .from("event_dates")
      .delete()
      .in(
        "id",
        testDates.map((d) => d.id)
      );

    if (deleteError) {
      throw deleteError;
    }

    log(`Cleaned up ${testDates.length} event dates`, "debug");
    return testDates.length;
  }

  return 0;
}

async function cleanupEvents() {
  const { data, error } = await supabase
    .from("events")
    .delete()
    .like("title", `${TEST_CONFIG.TEST_PREFIX}%`);

  if (error && error.code !== "PGRST116") {
    throw error;
  }

  const count = data?.length || 0;
  if (count > 0) {
    log(`Cleaned up ${count} events`, "debug");
  }
  return count;
}
