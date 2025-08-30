#!/usr/bin/env node

/**
 * Test script for the improved cleanup system
 * This script demonstrates the new tracking and cleanup capabilities
 */

import { EventsFixtures } from "./features/events/fixtures.js";
import { globalCleanupCoordinator } from "./shared/utilities/cleanup-coordinator.js";
import { log } from "./shared/utilities/test-utils.js";

async function testImprovedCleanup() {
  log("🧪 Testing improved cleanup system...", "info");

  const fixtures = new EventsFixtures();

  try {
    // Create some test data to verify cleanup
    log("Creating test data...", "info");

    // Create a simple event
    const event = await fixtures.createTestEvent({
      post: { title: "TEST_CleanupDemo_Event" },
      tickets: [
        {
          title: "TEST_CleanupDemo_Ticket",
          description: "Test ticket for cleanup demo",
          price: 1000,
          quantity: 5,
        },
      ],
    });

    log(
      `Created event: ${event.event.id} with ticket: ${event.tickets[0].id}`,
      "debug"
    );

    // Create a test purchase
    log("Creating test purchase...", "info");
    const purchase = await fixtures.createTestEventPurchase(
      event.event.id,
      event.tickets[0].id,
      event.dates[0].id,
      {
        quantity: 2,
        customerEmail: "cleanup.test@example.com",
        customerName: "Cleanup Test User",
        useAuthentication: false, // Use guest purchase to test
      }
    );

    log(
      `Created purchase: ${purchase.purchase_id} with booking: ${purchase.booking_id}`,
      "debug"
    );

    // Show cleanup status before cleanup
    const statusBefore = fixtures.getCleanupStatus();
    log("Cleanup status before cleanup:", "info");
    console.log(JSON.stringify(statusBefore, null, 2));

    // Test the improved cleanup
    log("Testing improved cleanup...", "info");
    const cleanedRecords = await fixtures.cleanup();

    log(`Cleanup completed: ${cleanedRecords} records removed`, "success");

    // Show cleanup status after cleanup
    const statusAfter = fixtures.getCleanupStatus();
    log("Cleanup status after cleanup:", "info");
    console.log(JSON.stringify(statusAfter, null, 2));

    // Verify cleanup
    const verificationPassed = await globalCleanupCoordinator.verifyCleanup();

    if (verificationPassed) {
      log("✅ Cleanup verification passed!", "success");
    } else {
      log("⚠️ Cleanup verification found remaining data", "warning");

      // Run emergency cleanup if needed
      log("Running emergency cleanup...", "info");
      await globalCleanupCoordinator.emergencyCleanup(1);

      // Verify again
      const secondVerification = await globalCleanupCoordinator.verifyCleanup();
      if (secondVerification) {
        log("✅ Emergency cleanup successful!", "success");
      } else {
        log("❌ Emergency cleanup failed", "error");
      }
    }
  } catch (error) {
    log(`Test failed: ${error.message}`, "error");
    console.error(error.stack);

    // Ensure cleanup happens even on error
    try {
      await fixtures.cleanup();
    } catch (cleanupError) {
      log(`Cleanup after error failed: ${cleanupError.message}`, "error");
      await globalCleanupCoordinator.emergencyCleanup(1);
    }
  }
}

// Run the test
testImprovedCleanup()
  .then(() => {
    log("🎉 Improved cleanup test completed", "success");
    process.exit(0);
  })
  .catch((error) => {
    log(`💥 Test failed: ${error.message}`, "error");
    process.exit(1);
  });

