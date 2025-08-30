#!/usr/bin/env node

import { supabase } from "./config/database.js";

async function checkViewStructure() {
  console.log("🔍 CHECKING VIEW STRUCTURES");
  console.log("===========================\n");

  // Check event_details_view first (dependency)
  console.log("📋 EVENT_DETAILS_VIEW:");
  try {
    const { data, error } = await supabase
      .from("event_details_view")
      .select("*")
      .limit(1);

    if (error) {
      console.log("❌ Error:", error.message);
    } else if (data && data.length > 0) {
      console.log("✅ View exists and has data");
      console.log("📋 Columns:", Object.keys(data[0]).join(", "));
    } else {
      console.log("⚠️  View exists but is empty");
    }
  } catch (err) {
    console.log("❌ Error:", err.message);
  }

  // Check comprehensive_events_view
  console.log("\n📊 COMPREHENSIVE_EVENTS_VIEW:");
  try {
    const { data, error } = await supabase
      .from("comprehensive_events_view")
      .select("*")
      .limit(1);

    if (error) {
      console.log("❌ Error:", error.message);

      // Try with specific columns to debug
      console.log("🔍 Trying with event_id only...");
      const { data: eventIdData, error: eventIdError } = await supabase
        .from("comprehensive_events_view")
        .select("event_id")
        .limit(1);

      if (eventIdError) {
        console.log("❌ event_id error:", eventIdError.message);
      } else {
        console.log("✅ event_id accessible");
      }
    } else if (data && data.length > 0) {
      console.log("✅ View exists and has data");
      console.log("📋 Columns:", Object.keys(data[0]).join(", "));
      console.log("📊 Sample record (truncated):");
      const sample = { ...data[0] };
      // Truncate long fields for readability
      Object.keys(sample).forEach((key) => {
        if (typeof sample[key] === "string" && sample[key].length > 100) {
          sample[key] = sample[key].substring(0, 100) + "...";
        }
      });
      console.log(JSON.stringify(sample, null, 2));
    } else {
      console.log("⚠️  View exists but is empty");

      // Check total count
      const { count, error: countError } = await supabase
        .from("comprehensive_events_view")
        .select("*", { count: "exact", head: true });

      if (countError) {
        console.log("❌ Count error:", countError.message);
      } else {
        console.log(`📊 View has ${count} total records`);
      }
    }
  } catch (err) {
    console.log("❌ Error:", err.message);
  }

  // Check if there's any data in events table
  console.log("\n📋 EVENTS TABLE DATA:");
  try {
    const { data: events, error: eventsError } = await supabase
      .from("events")
      .select("*, posts!inner(*)")
      .limit(3);

    if (eventsError) {
      console.log("❌ Error:", eventsError.message);
    } else {
      console.log(`✅ Found ${events?.length || 0} events`);
      if (events && events.length > 0) {
        console.log("📊 Sample event:");
        console.log(JSON.stringify(events[0], null, 2));
      }
    }
  } catch (err) {
    console.log("❌ Error:", err.message);
  }

  // Check event_tickets_view
  console.log("\n🎫 EVENT_TICKETS_VIEW:");
  try {
    const { data, error } = await supabase
      .from("event_tickets_view")
      .select("*")
      .limit(1);

    if (error) {
      console.log("❌ Error:", error.message);
    } else if (data && data.length > 0) {
      console.log("✅ View exists and has data");
      console.log("📋 Columns:", Object.keys(data[0]).join(", "));
    } else {
      console.log("⚠️  View exists but is empty");
    }
  } catch (err) {
    console.log("❌ Error:", err.message);
  }

  // Check RPC functions
  console.log("\n🔧 CHECKING RPC FUNCTIONS:");

  const functionsToTest = [
    "create_event_purchase",
    "book_event_with_credits",
    "create_event_with_details",
  ];

  for (const funcName of functionsToTest) {
    try {
      await supabase.rpc(funcName, {});
      console.log(`✅ ${funcName}: EXISTS`);
    } catch (error) {
      if (
        error.message.includes("not found") ||
        error.message.includes("does not exist")
      ) {
        console.log(`❌ ${funcName}: DOES NOT EXIST`);
      } else {
        console.log(
          `✅ ${funcName}: EXISTS (got expected error: ${error.message.substring(
            0,
            80
          )}...)`
        );
      }
    }
  }
}

checkViewStructure().catch(console.error);
