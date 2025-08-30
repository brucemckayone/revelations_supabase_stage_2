#!/usr/bin/env node

/**
 * Debug script to check table schemas and understand column availability
 */

import { supabase } from "./config/database.js";
import { log } from "./shared/utilities/test-utils.js";

async function debugSchema() {
  log("🔍 Debugging table schemas...", "info");

  const tablesToCheck = [
    "universal_package_purchases",
    "event_bookings",
    "purchases",
    "tickets",
    "event_dates",
  ];

  for (const table of tablesToCheck) {
    try {
      console.log(`\n--- ${table.toUpperCase()} SCHEMA ---`);

      // Get one record to see the actual columns
      const { data: sample, error } = await supabase
        .from(table)
        .select("*")
        .limit(1);

      if (error) {
        console.log(`Error: ${error.message}`);
        continue;
      }

      if (sample && sample.length > 0) {
        console.log("Available columns:");
        Object.keys(sample[0]).forEach((col) => {
          console.log(
            `  - ${col}: ${typeof sample[0][col]} (${sample[0][col]})`
          );
        });
      } else {
        console.log("No records found, checking via introspection...");

        // Try to insert and see what error we get to understand required columns
        try {
          await supabase.from(table).insert({}).select();
        } catch (insertError) {
          console.log(
            `Insert error reveals constraints: ${insertError.message}`
          );
        }
      }
    } catch (error) {
      console.log(`Failed to check ${table}: ${error.message}`);
    }
  }

  // Specifically check the universal_package_purchases issue
  console.log(`\n--- UNIVERSAL_PACKAGE_PURCHASES DETAILED CHECK ---`);
  try {
    // Try to select with user_id
    const { error: userIdError } = await supabase
      .from("universal_package_purchases")
      .select("user_id")
      .limit(1);

    if (userIdError) {
      console.log(`user_id column error: ${userIdError.message}`);
    } else {
      console.log("user_id column exists and is accessible");
    }

    // Try to select with purchase_id
    const { error: purchaseIdError } = await supabase
      .from("universal_package_purchases")
      .select("purchase_id")
      .limit(1);

    if (purchaseIdError) {
      console.log(`purchase_id column error: ${purchaseIdError.message}`);
    } else {
      console.log("purchase_id column exists and is accessible");
    }
  } catch (error) {
    console.log(`Universal package purchases check failed: ${error.message}`);
  }

  // Check what's preventing ticket deletion
  console.log(`\n--- FOREIGN KEY CONSTRAINTS CHECK ---`);

  try {
    // Try to delete a ticket to see the exact constraint
    const { data: tickets } = await supabase
      .from("tickets")
      .select("id")
      .limit(1);

    if (tickets && tickets.length > 0) {
      console.log(
        `Attempting to delete ticket ${tickets[0].id} to see constraint...`
      );

      const { error: deleteError } = await supabase
        .from("tickets")
        .delete()
        .eq("id", tickets[0].id);

      if (deleteError) {
        console.log(`Constraint error: ${deleteError.message}`);
      } else {
        console.log("Ticket deleted successfully (unexpected!)");
      }
    }
  } catch (error) {
    console.log(`Constraint check failed: ${error.message}`);
  }
}

debugSchema()
  .then(() => {
    log("🔍 Schema debug completed", "success");
    process.exit(0);
  })
  .catch((error) => {
    log(`Schema debug failed: ${error.message}`, "error");
    process.exit(1);
  });

