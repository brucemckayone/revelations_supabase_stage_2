#!/usr/bin/env node

/**
 * Force cleanup script for removing all test data
 * Use this when normal cleanup fails due to constraint violations
 */

import { EventsForceCleanup } from "./features/events/force-cleanup.js";
import { globalCleanupCoordinator } from "./shared/utilities/cleanup-coordinator.js";
import { log } from "./shared/utilities/test-utils.js";

async function runForceCleanup() {
  log("🚨 Starting force cleanup of all test data...", "info");

  try {
    // Run the events force cleanup (most comprehensive)
    const eventsResult = await EventsForceCleanup.forceCleanAllTestData(2);
    log(`Events force cleanup: ${eventsResult} records removed`, "info");

    // Run the global emergency cleanup for any remaining data
    const globalResult = await globalCleanupCoordinator.emergencyCleanup(2);
    log(`Global emergency cleanup completed`, "info");

    // Verify cleanup
    const verificationPassed = await globalCleanupCoordinator.verifyCleanup();

    if (verificationPassed) {
      log("✅ Force cleanup verification passed!", "success");
      log("🎉 All test data has been cleaned up successfully", "success");
    } else {
      log("⚠️ Some test data may still remain", "warning");
      log("You may need to manually check and clean remaining records", "info");
    }

    process.exit(0);
  } catch (error) {
    log(`💥 Force cleanup failed: ${error.message}`, "error");
    console.error(error.stack);
    process.exit(1);
  }
}

// Show help if requested
if (process.argv.includes("--help") || process.argv.includes("-h")) {
  console.log(`
🚨 Force Cleanup Script
========================

This script performs aggressive cleanup of all test data, including:
- Event bookings and purchases (the main constraint blockers)
- Universal package data
- Posts, events, tickets, and related data
- Test tags and associations

Usage:
  node force-cleanup-all.js

This script will:
1. Delete all test data from the last 2 hours
2. Handle foreign key constraints by deleting in proper order
3. Verify that cleanup was successful

⚠️  WARNING: This will permanently delete test data!
Only run this on test/development databases.
`);
  process.exit(0);
}

// Confirm before running
console.log("⚠️  This will force delete all test data from the last 2 hours.");
console.log("🎯 Press Ctrl+C to cancel, or Enter to continue...");

process.stdin.once("data", () => {
  runForceCleanup();
});

// Auto-run if in CI or with --force flag
if (process.env.CI || process.argv.includes("--force")) {
  runForceCleanup();
}

