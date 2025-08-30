#!/usr/bin/env node

/**
 * Debug script to check what test data exists in the database
 */

import { supabase } from "./config/database.js";
import { log } from "./shared/utilities/test-utils.js";

async function debugTestData() {
  log("🔍 Debugging test data in database...", "info");

  const tables = [
    "posts",
    "events",
    "event_dates",
    "tickets",
    "event_bookings",
    "purchases",
    "universal_packages",
    "universal_package_purchases",
    "universal_package_event_usage",
    "post_tags",
    "tags",
  ];

  for (const table of tables) {
    try {
      console.log(`\n--- ${table.toUpperCase()} ---`);

      // Count total records
      const { count: totalCount } = await supabase
        .from(table)
        .select("*", { count: "exact", head: true });

      console.log(`Total records: ${totalCount}`);

      // Look for test-related records with different patterns
      const patterns = [
        { name: "TEST_%", field: "title" },
        { name: "TEST_%", field: "name" },
        { name: "TEST-%", field: "ticket_code" },
        { name: "pi_test_%", field: "stripe_payment_intent_id" },
        { name: "test_%", field: "stripe_payment_intent_id" },
      ];

      for (const pattern of patterns) {
        try {
          const { data, count } = await supabase
            .from(table)
            .select("*", { count: "exact" })
            .like(pattern.field, pattern.name)
            .limit(5);

          if (count > 0) {
            console.log(
              `  ${pattern.field} LIKE '${pattern.name}': ${count} records`
            );
            if (data && data.length > 0) {
              console.log(
                `    Sample: ${JSON.stringify(data[0], null, 2).substring(
                  0,
                  200
                )}...`
              );
            }
          }
        } catch (error) {
          // Field doesn't exist in this table, skip
        }
      }

      // Check for recent records (last 2 hours)
      try {
        const twoHoursAgo = new Date(
          Date.now() - 2 * 60 * 60 * 1000
        ).toISOString();
        const { count: recentCount } = await supabase
          .from(table)
          .select("*", { count: "exact", head: true })
          .gte("created_at", twoHoursAgo);

        if (recentCount > 0) {
          console.log(`  Recent records (last 2h): ${recentCount}`);
        }
      } catch (error) {
        // No created_at field
      }

      // Check for metadata-based test records
      if (table === "purchases") {
        try {
          const { count: testPurchases } = await supabase
            .from(table)
            .select("*", { count: "exact", head: true })
            .eq("metadata->>'test_purchase'", "true");

          if (testPurchases > 0) {
            console.log(`  Test purchases (metadata): ${testPurchases}`);
          }
        } catch (error) {
          // Metadata query failed
        }
      }
    } catch (error) {
      console.log(`  Error querying ${table}: ${error.message}`);
    }
  }

  // Check for any foreign key relationships that might be blocking
  console.log(`\n--- RELATIONSHIP ANALYSIS ---`);

  try {
    // Check event_bookings that might be preventing ticket deletion
    const { data: bookings } = await supabase
      .from("event_bookings")
      .select("id, ticket_id, purchase_id, ticket_code, created_at")
      .order("created_at", { ascending: false })
      .limit(10);

    console.log(`Recent event_bookings (${bookings?.length || 0}):`);
    bookings?.forEach((booking) => {
      console.log(
        `  Booking ${booking.id}: ticket=${booking.ticket_id}, purchase=${booking.purchase_id}, code=${booking.ticket_code}`
      );
    });
  } catch (error) {
    console.log(`Error checking bookings: ${error.message}`);
  }

  try {
    // Check purchases that might be preventing booking deletion
    const { data: purchases } = await supabase
      .from("purchases")
      .select(
        "id, purchase_type, amount, stripe_payment_intent_id, metadata, created_at"
      )
      .order("created_at", { ascending: false })
      .limit(10);

    console.log(`Recent purchases (${purchases?.length || 0}):`);
    purchases?.forEach((purchase) => {
      console.log(
        `  Purchase ${purchase.id}: type=${purchase.purchase_type}, amount=${purchase.amount}, intent=${purchase.stripe_payment_intent_id}`
      );
    });
  } catch (error) {
    console.log(`Error checking purchases: ${error.message}`);
  }
}

debugTestData()
  .then(() => {
    log("🔍 Debug completed", "success");
    process.exit(0);
  })
  .catch((error) => {
    log(`Debug failed: ${error.message}`, "error");
    process.exit(1);
  });

