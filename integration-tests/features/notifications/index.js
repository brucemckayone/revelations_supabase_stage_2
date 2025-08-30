import { TestSuite } from "../../core/test-framework.js";
import { runNotificationCreationTests } from "./tests/notification-creation.test.js";
import { runNotificationDeliveryTests } from "./tests/notification-delivery.test.js";
import { runNotificationDeliveryComprehensiveTests } from "./tests/notification-delivery-comprehensive.test.js";
import { runNotificationPreferencesTests } from "./tests/notification-preferences.test.js";
import { runNotificationTemplatesTests } from "./tests/notification-templates.test.js";
import { runNotificationBroadcastTests } from "./tests/notification-broadcast.test.js";
import { runNotificationSecurityTests } from "./tests/notification-security.test.js";
import { runNotificationSystemIntegrationTests } from "./tests/notification-system-integration.test.js";
import { cleanup } from "./cleanup.js";

export const metadata = {
  name: "Notification System",
  description:
    "Comprehensive tests for multi-channel notification system with templates, preferences, and delivery tracking",
  dependencies: [], // Notifications are foundational - no dependencies
  cleanup_order: 1, // Clean up early since other systems may depend on notifications
};

export async function runTests() {
  const suite = new TestSuite(metadata.name, metadata.description);

  // Core notification functionality
  suite.addTest("Notification Creation Tests", runNotificationCreationTests);

  // Multi-channel delivery system
  suite.addTest("Notification Delivery Tests", runNotificationDeliveryTests);

  // Comprehensive delivery with stubs
  suite.addTest(
    "Comprehensive Delivery Tests",
    runNotificationDeliveryComprehensiveTests
  );

  // User preferences and settings
  suite.addTest(
    "Notification Preferences Tests",
    runNotificationPreferencesTests
  );

  // Template system
  suite.addTest("Notification Templates Tests", runNotificationTemplatesTests);

  // Broadcast and bulk messaging
  suite.addTest("Notification Broadcast Tests", runNotificationBroadcastTests);

  // Security and access control
  suite.addTest("Notification Security Tests", runNotificationSecurityTests);

  // Integration with other systems
  suite.addTest(
    "Notification System Integration Tests",
    runNotificationSystemIntegrationTests
  );

  return await suite.run();
}

export { cleanup };
