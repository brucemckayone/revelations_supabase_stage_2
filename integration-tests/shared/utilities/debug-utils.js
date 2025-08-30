/**
 * Debug utilities for integration tests
 * Provides helpful debugging functions and data inspection tools
 */

import { supabase } from "../../config/database.js";
import { log } from "./test-utils.js";

/**
 * Debug breakpoint with context information
 */
export function debugBreakpoint(context = "Debug Point", data = null) {
  console.log(`\n🔍 DEBUG BREAKPOINT: ${context}`);
  console.log("=".repeat(50));

  if (data) {
    console.log("📊 Data:", JSON.stringify(data, null, 2));
  }

  console.log("🕒 Timestamp:", new Date().toISOString());
  console.log("📍 Stack trace:");
  console.trace();
  console.log("=".repeat(50));

  // This will pause execution in the debugger
  debugger;
}

/**
 * Inspect database state at a specific point
 */
export async function inspectDatabaseState(tables = []) {
  const defaultTables = [
    "posts",
    "events",
    "event_dates",
    "tickets",
    "event_bookings",
    "purchases",
    "universal_packages",
    "universal_package_purchases",
  ];

  const tablesToInspect = tables.length > 0 ? tables : defaultTables;

  console.log("\n🔍 DATABASE STATE INSPECTION");
  console.log("=".repeat(50));

  for (const table of tablesToInspect) {
    try {
      const { count } = await supabase
        .from(table)
        .select("*", { count: "exact", head: true });

      console.log(`📊 ${table}: ${count} records`);

      // Show recent records for key tables
      if (
        ["event_bookings", "purchases", "events"].includes(table) &&
        count > 0
      ) {
        const { data } = await supabase
          .from(table)
          .select("*")
          .order("created_at", { ascending: false })
          .limit(3);

        if (data && data.length > 0) {
          console.log(`   Recent records:`);
          data.forEach((record, index) => {
            console.log(
              `   ${index + 1}. ID: ${record.id} (${
                record.created_at || "no timestamp"
              })`
            );
          });
        }
      }
    } catch (error) {
      console.log(`❌ ${table}: Error - ${error.message}`);
    }
  }

  console.log("=".repeat(50));
}

/**
 * Wait for user input to continue (useful for step debugging)
 */
export async function waitForInput(message = "Press Enter to continue...") {
  console.log(`\n⏸️  ${message}`);

  return new Promise((resolve) => {
    process.stdin.once("data", () => {
      resolve();
    });
  });
}

/**
 * Detailed error inspection
 */
export function inspectError(error, context = "Error Analysis") {
  console.log(`\n💥 ${context.toUpperCase()}`);
  console.log("=".repeat(50));
  console.log("📋 Message:", error.message);
  console.log("🏷️  Name:", error.name);

  if (error.code) {
    console.log("🔢 Code:", error.code);
  }

  if (error.details) {
    console.log("📝 Details:", error.details);
  }

  if (error.hint) {
    console.log("💡 Hint:", error.hint);
  }

  if (error.stack) {
    console.log("📍 Stack Trace:");
    console.log(error.stack);
  }

  console.log("=".repeat(50));
}

/**
 * Performance timing utility
 */
export class DebugTimer {
  constructor(name = "Operation") {
    this.name = name;
    this.startTime = Date.now();
    this.checkpoints = [];

    console.log(`⏱️  Started timing: ${this.name}`);
  }

  checkpoint(label) {
    const now = Date.now();
    const elapsed = now - this.startTime;
    const sinceLastCheckpoint =
      this.checkpoints.length > 0
        ? now - this.checkpoints[this.checkpoints.length - 1].time
        : elapsed;

    this.checkpoints.push({
      label,
      time: now,
      elapsed,
      sinceLastCheckpoint,
    });

    console.log(
      `⏱️  ${this.name} - ${label}: ${elapsed}ms (+${sinceLastCheckpoint}ms)`
    );
  }

  end() {
    const totalTime = Date.now() - this.startTime;
    console.log(`⏱️  Finished timing: ${this.name} - Total: ${totalTime}ms`);

    if (this.checkpoints.length > 0) {
      console.log("📊 Checkpoint Summary:");
      this.checkpoints.forEach((checkpoint, index) => {
        console.log(
          `   ${index + 1}. ${checkpoint.label}: ${checkpoint.elapsed}ms`
        );
      });
    }

    return totalTime;
  }
}

/**
 * Memory usage inspection
 */
export function inspectMemoryUsage(label = "Memory Check") {
  const used = process.memoryUsage();

  console.log(`\n🧠 ${label.toUpperCase()}`);
  console.log("=".repeat(30));

  for (let key in used) {
    const value = Math.round((used[key] / 1024 / 1024) * 100) / 100;
    console.log(`${key}: ${value} MB`);
  }

  console.log("=".repeat(30));
}

/**
 * Supabase query debugging wrapper
 */
export async function debugQuery(queryBuilder, label = "Query") {
  console.log(`\n🔍 Executing ${label}...`);

  const timer = new DebugTimer(label);

  try {
    const result = await queryBuilder;
    timer.end();

    console.log(`✅ ${label} successful`);
    console.log(`📊 Result:`, {
      data: result.data ? `${result.data.length} records` : "No data",
      error: result.error ? result.error.message : "None",
      count: result.count || "Not requested",
    });

    return result;
  } catch (error) {
    timer.end();
    console.log(`❌ ${label} failed`);
    inspectError(error, label);
    throw error;
  }
}

/**
 * Function execution tracer
 */
export function traceFunction(fn, name = fn.name || "Anonymous Function") {
  return async function (...args) {
    console.log(`\n🔄 Entering: ${name}`);
    console.log(`📥 Arguments:`, args.length > 0 ? args : "None");

    const timer = new DebugTimer(name);

    try {
      const result = await fn.apply(this, args);
      timer.end();

      console.log(`✅ Exiting: ${name}`);
      console.log(
        `📤 Result:`,
        typeof result === "object" ? JSON.stringify(result, null, 2) : result
      );

      return result;
    } catch (error) {
      timer.end();
      console.log(`❌ Error in: ${name}`);
      inspectError(error, name);
      throw error;
    }
  };
}

/**
 * Test data snapshot for debugging
 */
export async function createTestDataSnapshot(label = "Test Data Snapshot") {
  const snapshot = {
    timestamp: new Date().toISOString(),
    label,
    data: {},
  };

  const tables = [
    "posts",
    "events",
    "event_dates",
    "tickets",
    "event_bookings",
    "purchases",
  ];

  for (const table of tables) {
    try {
      const { data, count } = await supabase
        .from(table)
        .select("*", { count: "exact" })
        .order("created_at", { ascending: false })
        .limit(10);

      snapshot.data[table] = {
        count,
        recentRecords: data || [],
      };
    } catch (error) {
      snapshot.data[table] = {
        error: error.message,
      };
    }
  }

  console.log(`\n📸 ${label.toUpperCase()}`);
  console.log("=".repeat(50));
  console.log(JSON.stringify(snapshot, null, 2));
  console.log("=".repeat(50));

  return snapshot;
}

/**
 * Interactive debugger - allows choosing what to inspect
 */
export async function interactiveDebugger() {
  console.log("\n🔧 INTERACTIVE DEBUGGER");
  console.log("=".repeat(30));
  console.log("1. Inspect Database State");
  console.log("2. Check Memory Usage");
  console.log("3. Create Data Snapshot");
  console.log("4. Continue Execution");
  console.log("0. Exit");

  // This is a simplified version - in a real scenario you'd want proper input handling
  console.log("\nChoose an option and then continue in your debugger...");
  debugger;
}

// Export all debugging utilities
export default {
  debugBreakpoint,
  inspectDatabaseState,
  waitForInput,
  inspectError,
  DebugTimer,
  inspectMemoryUsage,
  debugQuery,
  traceFunction,
  createTestDataSnapshot,
  interactiveDebugger,
};

