#!/usr/bin/env node

/**
 * Debug runner for individual test files
 * Usage: node debug-single-test.js <test-name>
 * Examples:
 *   node debug-single-test.js event-capacity
 *   node debug-single-test.js event-booking
 *   node debug-single-test.js event-credits
 */

import { testConnection } from "./config/database.js";
import { log } from "./shared/utilities/test-utils.js";

// Import test functions
import { runEventCapacityTests } from "./features/events/tests/event-capacity.test.js";
import { runEventBookingTests } from "./features/events/tests/event-booking.test.js";
import { runEventCreditsTests } from "./features/events/tests/event-credits.test.js";

const testMap = {
  "event-capacity": {
    name: "Event Capacity & Availability Tests",
    runner: runEventCapacityTests,
    description:
      "Tests for ticket availability, capacity limits, and overbooking prevention",
  },
  "event-booking": {
    name: "Event Booking & Purchase Tests",
    runner: runEventBookingTests,
    description:
      "Tests for event purchasing, guest bookings, and ticket generation",
  },
  "event-credits": {
    name: "Universal Package Credits Tests",
    runner: runEventCreditsTests,
    description:
      "Tests for credit-based event booking and universal package integration",
  },
};

async function runSingleTest() {
  const testName = process.argv[2];

  if (!testName) {
    console.log("🔧 Debug Single Test Runner");
    console.log("============================\n");
    console.log("Usage: node debug-single-test.js <test-name>\n");
    console.log("Available tests:");
    Object.entries(testMap).forEach(([key, test]) => {
      console.log(`  ${key.padEnd(15)} - ${test.description}`);
    });
    console.log("\nExamples:");
    console.log("  node debug-single-test.js event-capacity");
    console.log("  npm run debug:capacity");
    console.log("  node --inspect-brk debug-single-test.js event-booking");
    process.exit(0);
  }

  const test = testMap[testName];
  if (!test) {
    log(`❌ Unknown test: ${testName}`, "error");
    log(`Available tests: ${Object.keys(testMap).join(", ")}`, "info");
    process.exit(1);
  }

  console.log("🔧 Debug Mode - Single Test Runner");
  console.log("===================================");
  console.log(`📋 Test: ${test.name}`);
  console.log(`📝 ${test.description}`);
  console.log("-----------------------------------\n");

  try {
    // Test database connection
    log("Testing database connection...", "info");
    await testConnection();
    log("Database connection successful ✅", "success");
    console.log("");

    // Add debugging helpers
    console.log("🔍 Debugging Tips:");
    console.log("  - Set breakpoints in your IDE or use debugger; statements");
    console.log("  - Use console.log() for quick debugging");
    console.log("  - Check the browser DevTools at chrome://inspect");
    console.log("  - Press Ctrl+C to stop the debugger");
    console.log("");

    // Run the specific test
    log(`🚀 Starting test: ${test.name}`, "info");
    const startTime = Date.now();

    await test.runner();

    const duration = ((Date.now() - startTime) / 1000).toFixed(2);
    log(`✅ Test completed successfully in ${duration}s`, "success");
  } catch (error) {
    log(`❌ Test failed: ${error.message}`, "error");
    console.error("\n📊 Full Error Details:");
    console.error(error);

    if (error.stack) {
      console.error("\n📍 Stack Trace:");
      console.error(error.stack);
    }

    process.exit(1);
  }
}

// Handle process signals for clean debugging
process.on("SIGINT", () => {
  console.log("\n\n🛑 Debug session interrupted");
  process.exit(0);
});

process.on("SIGTERM", () => {
  console.log("\n\n🛑 Debug session terminated");
  process.exit(0);
});

// Add unhandled rejection handling for debugging
process.on("unhandledRejection", (reason, promise) => {
  console.error("\n💥 Unhandled Rejection at:", promise);
  console.error("📋 Reason:", reason);
});

process.on("uncaughtException", (error) => {
  console.error("\n💥 Uncaught Exception:", error);
  process.exit(1);
});

// Run the single test
runSingleTest();

