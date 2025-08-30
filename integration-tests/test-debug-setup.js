#!/usr/bin/env node

/**
 * Simple test to verify the debugging setup works correctly
 * This file can be used to test breakpoints, debugging utilities, and VS Code integration
 */

import { testConnection } from "./config/database.js";
import { log } from "./shared/utilities/test-utils.js";
import debug from "./shared/utilities/debug-utils.js";

async function testDebuggingSetup() {
  console.log("🔧 Testing Debug Setup");
  console.log("======================\n");

  try {
    // Test 1: Database connection
    log("Testing database connection...", "info");
    await testConnection();
    log("✅ Database connection successful", "success");

    // Test 2: Debug utilities
    log("Testing debug utilities...", "info");

    // Test breakpoint (will pause if debugger is attached)
    debug.debugBreakpoint("Testing debug breakpoint", {
      test: "debugging setup",
      timestamp: new Date().toISOString(),
    });

    // Test memory inspection
    debug.inspectMemoryUsage("Debug Setup Test");

    // Test timer
    const timer = new debug.DebugTimer("Debug Test Operations");
    timer.checkpoint("Completed connection test");
    timer.checkpoint("Completed debug utilities test");
    timer.end();

    // Test database state (just count a few basic tables)
    await debug.inspectDatabaseState(["posts", "events"]);

    // Test 3: Simple data snapshot
    await debug.createTestDataSnapshot("Debug Setup Test");

    console.log("\n🎉 Debug setup test completed successfully!");
    console.log("✅ All debugging utilities are working correctly");
    console.log("✅ Database connection is functional");
    console.log("✅ Memory inspection is available");
    console.log("✅ Performance timing is operational");
    console.log("✅ Database state inspection is working");

    log("Debug setup verification successful! 🚀", "success");
  } catch (error) {
    log(`❌ Debug setup test failed: ${error.message}`, "error");
    debug.inspectError(error, "Debug Setup Test Error");
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on("SIGINT", () => {
  console.log("\n\n🛑 Debug setup test interrupted");
  process.exit(0);
});

process.on("SIGTERM", () => {
  console.log("\n\n🛑 Debug setup test terminated");
  process.exit(0);
});

// Add debugging info
console.log("🔍 Debug Setup Test");
console.log("===================");
console.log(`📂 Working Directory: ${process.cwd()}`);
console.log(`🎯 Node Version: ${process.version}`);
console.log(`🔧 Environment: ${process.env.NODE_ENV || "development"}`);
console.log(
  `⚡ Debug Mode: ${
    process.debugPort ? "Enabled on port " + process.debugPort : "Disabled"
  }`
);
console.log("");

// Run the test
testDebuggingSetup();


