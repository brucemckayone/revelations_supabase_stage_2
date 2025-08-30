#!/usr/bin/env node

/**
 * Single Test Runner
 *
 * Runs individual test files from the events system
 */

import { testConnection } from "./config/database.js";

const testName = process.argv[2];

if (!testName) {
  console.log(`
Usage: node run-single-test.js <test-name>

Available tests:
  event-creation     - Event creation and management tests
  event-booking      - Event booking and purchase tests  
  event-credits      - Universal package credit tests
  event-capacity     - Event capacity and availability tests
  event-cancellation - Event cancellation and refund tests
  
  notification-creation     - Notification creation and validation tests
  notification-delivery     - Multi-channel delivery system tests
  notification-preferences  - User notification preferences tests
  notification-templates    - Email and notification template tests
  notification-broadcast    - Broadcast and bulk messaging tests
  notification-security     - Security and access control tests
  notification-delivery-comprehensive - Comprehensive delivery with stubs
  notification-integration  - System integration and trigger tests
`);
  process.exit(1);
}

const TEST_MODULES = {
  "event-creation": () =>
    import("./features/events/tests/event-creation.test.js").then(
      (m) => m.runEventCreationTests
    ),
  "event-booking": () =>
    import("./features/events/tests/event-booking.test.js").then(
      (m) => m.runEventBookingTests
    ),
  "event-credits": () =>
    import("./features/events/tests/event-credits.test.js").then(
      (m) => m.runEventCreditsTests
    ),
  "event-capacity": () =>
    import("./features/events/tests/event-capacity.test.js").then(
      (m) => m.runEventCapacityTests
    ),
  "event-cancellation": () =>
    import("./features/events/tests/event-cancellation.test.js").then(
      (m) => m.runEventCancellationTests
    ),

  "notification-creation": () =>
    import("./features/notifications/tests/notification-creation.test.js").then(
      (m) => m.runNotificationCreationTests
    ),
  "notification-delivery": () =>
    import("./features/notifications/tests/notification-delivery.test.js").then(
      (m) => m.runNotificationDeliveryTests
    ),
  "notification-preferences": () =>
    import(
      "./features/notifications/tests/notification-preferences.test.js"
    ).then((m) => m.runNotificationPreferencesTests),
  "notification-templates": () =>
    import(
      "./features/notifications/tests/notification-templates.test.js"
    ).then((m) => m.runNotificationTemplatesTests),
  "notification-broadcast": () =>
    import(
      "./features/notifications/tests/notification-broadcast.test.js"
    ).then((m) => m.runNotificationBroadcastTests),
  "notification-security": () =>
    import("./features/notifications/tests/notification-security.test.js").then(
      (m) => m.runNotificationSecurityTests
    ),
  "notification-delivery-comprehensive": () =>
    import(
      "./features/notifications/tests/notification-delivery-comprehensive.test.js"
    ).then((m) => m.runNotificationDeliveryComprehensiveTests),
  "notification-integration": () =>
    import(
      "./features/notifications/tests/notification-system-integration.test.js"
    ).then((m) => m.runNotificationSystemIntegrationTests),
};

async function main() {
  console.log(`🧪 Running ${testName} tests`);
  console.log("=".repeat(50));

  // Test database connection
  console.log("📡 Testing database connection...");
  const connectionOk = await testConnection();
  if (!connectionOk) {
    console.error(
      "❌ Database connection failed. Check your .env configuration."
    );
    process.exit(1);
  }

  if (!TEST_MODULES[testName]) {
    console.error(`❌ Unknown test: ${testName}`);
    console.log(`Available tests: ${Object.keys(TEST_MODULES).join(", ")}`);
    process.exit(1);
  }

  try {
    const testRunner = await TEST_MODULES[testName]();

    console.log("🚀 Starting test execution...\n");
    await testRunner();

    // If we get here without error, the test passed
    console.log(`\n✅ ${testName} tests completed successfully!`);
    process.exit(0);
  } catch (error) {
    console.error(`\n❌ Test execution failed: ${error.message}`);
    console.error(error.stack);
    process.exit(1);
  }
}

main();
