#!/usr/bin/env node

/**
 * Script to inspect the actual database schema and verify what exists
 */

import { supabase } from "./config/database.js";

async function inspectSchema() {
  console.log("🔍 INSPECTING ACTUAL DATABASE SCHEMA");
  console.log("=====================================\n");

  try {
    // Check for views
    console.log("📊 CHECKING VIEWS...");
    const { data: views, error: viewsError } = await supabase.rpc("exec_sql", {
      query: `SELECT schemaname, viewname FROM pg_views WHERE schemaname = 'public' ORDER BY viewname;`,
    });

    if (viewsError) {
      console.log("❌ Views error:", viewsError.message);
    } else if (views && views.length > 0) {
      views.forEach((view) => console.log(`  - ${view.viewname}`));
    } else {
      console.log("  No views found in public schema");
    }

    // Check for event-related tables
    console.log("\n📋 CHECKING EVENT-RELATED TABLES...");
    const { data: eventTables, error: eventTablesError } = await supabase.rpc(
      "exec_sql",
      {
        query: `SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE '%event%' ORDER BY tablename;`,
      }
    );

    if (eventTablesError) {
      console.log("❌ Event tables error:", eventTablesError.message);
    } else if (eventTables && eventTables.length > 0) {
      eventTables.forEach((table) => console.log(`  - ${table.tablename}`));
    } else {
      console.log("  No event-related tables found");
    }

    // Check all public tables
    console.log("\n📋 CHECKING ALL PUBLIC TABLES...");
    const { data: allTables, error: allTablesError } = await supabase.rpc(
      "exec_sql",
      {
        query: `SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;`,
      }
    );

    if (allTablesError) {
      console.log("❌ All tables error:", allTablesError.message);
    } else if (allTables && allTables.length > 0) {
      console.log("  Tables:", allTables.map((t) => t.tablename).join(", "));
    } else {
      console.log("  No tables found");
    }

    // Check for specific tables mentioned in design doc
    console.log("\n🎯 CHECKING SPECIFIC TABLES FROM DESIGN DOC...");
    const tablesToCheck = [
      "posts",
      "events",
      "event_dates",
      "tickets",
      "event_bookings",
      "purchases",
      "universal_packages",
      "universal_package_purchases",
      "universal_package_event_usage",
      "tags",
      "post_tags",
    ];

    for (const tableName of tablesToCheck) {
      try {
        const { count, error } = await supabase
          .from(tableName)
          .select("*", { count: "exact", head: true });

        if (error) {
          console.log(`  ❌ ${tableName}: ${error.message}`);
        } else {
          console.log(`  ✅ ${tableName}: exists (${count} records)`);
        }
      } catch (err) {
        console.log(`  ❌ ${tableName}: ${err.message}`);
      }
    }

    // Check for specific views mentioned in design doc
    console.log("\n🎯 CHECKING SPECIFIC VIEWS FROM DESIGN DOC...");
    const viewsToCheck = [
      "event_tickets_view",
      "comprehensive_events_view",
      "event_dates_view",
      "event_details_view",
    ];

    for (const viewName of viewsToCheck) {
      try {
        const { count, error } = await supabase
          .from(viewName)
          .select("*", { count: "exact", head: true });

        if (error) {
          console.log(`  ❌ ${viewName}: ${error.message}`);
        } else {
          console.log(`  ✅ ${viewName}: exists (${count} records)`);
        }
      } catch (err) {
        console.log(`  ❌ ${viewName}: ${err.message}`);
      }
    }

    // Check for functions mentioned in design doc
    console.log("\n🔧 CHECKING FUNCTIONS FROM DESIGN DOC...");
    const functionsToCheck = [
      "create_event_with_details",
      "create_event_purchase",
      "book_event_with_credits",
    ];

    const { data: functions, error: functionsError } = await supabase.rpc(
      "exec_sql",
      {
        query: `
        SELECT routine_name, routine_type 
        FROM information_schema.routines 
        WHERE routine_schema = 'public' 
        AND routine_name IN (${functionsToCheck.map((f) => `'${f}'`).join(",")})
        ORDER BY routine_name;
      `,
      }
    );

    if (functionsError) {
      console.log("❌ Functions error:", functionsError.message);
    } else if (functions && functions.length > 0) {
      functions.forEach((func) =>
        console.log(`  ✅ ${func.routine_name} (${func.routine_type})`)
      );
    } else {
      console.log("  ❌ None of the expected functions found");
    }

    // Sample some data from key tables
    console.log("\n📊 SAMPLING DATA FROM KEY TABLES...");

    try {
      const { data: eventSample } = await supabase
        .from("events")
        .select("*")
        .limit(1);

      if (eventSample && eventSample.length > 0) {
        console.log("\n📋 EVENTS TABLE STRUCTURE:");
        console.log("Columns:", Object.keys(eventSample[0]).join(", "));
      }
    } catch (err) {
      console.log("❌ Could not sample events table:", err.message);
    }

    try {
      const { data: ticketSample } = await supabase
        .from("tickets")
        .select("*")
        .limit(1);

      if (ticketSample && ticketSample.length > 0) {
        console.log("\n🎫 TICKETS TABLE STRUCTURE:");
        console.log("Columns:", Object.keys(ticketSample[0]).join(", "));
      }
    } catch (err) {
      console.log("❌ Could not sample tickets table:", err.message);
    }
  } catch (error) {
    console.error("❌ Schema inspection failed:", error.message);
  }
}

// Run the inspection
inspectSchema();


