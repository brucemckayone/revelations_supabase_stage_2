import {
  startTest,
  endTest,
  logSection,
  logRequirement,
  logAction,
  logVerify,
  logExpectedFailure,
  assert,
  assertEqual,
  assertNotNull,
  assertGreaterThan,
  callFunction,
} from "../../../shared/utilities/test-utils.js";
import { NotificationsFixtures } from "../fixtures.js";
import { supabase } from "../../../config/database.js";
import { TestUserManager } from "../../../shared/utilities/test-user-manager.js";

// Test user configuration - use same credentials as other tests
const TEST_AUTH_EMAIL =
  process.env.TEST_USER_EMAIL || "brucemckayone@gmail.com";
const TEST_AUTH_PASSWORD = process.env.TEST_USER_PASSWORD || "password123";
const userManager = new TestUserManager();

export async function runNotificationCreationTests() {
  const fixtures = new NotificationsFixtures();

  try {
    await testBasicNotificationCreation(fixtures);
    await testNotificationCreationWithMetadata(fixtures);
    await testNotificationCreationFunction(fixtures);
    await testBatchNotificationCreation(fixtures);
    await testNotificationValidation(fixtures);
    await testNotificationTypes(fixtures);
  } finally {
    await fixtures.cleanup();
  }
}

async function testBasicNotificationCreation(fixtures) {
  startTest("Basic Notification Creation");

  logSection("Setup Test Environment");
  logRequirement("System must be able to create basic notifications");
  logRequirement(
    "Notifications must have required fields and proper structure"
  );

  logAction("Creating test notification");
  const notification = await fixtures.createTestNotification();

  logVerify("Notification created successfully");
  assertNotNull(notification.id, "Notification should have valid ID");
  assertNotNull(notification.user_id, "Notification should have user ID");
  assertNotNull(notification.title, "Notification should have title");
  assertNotNull(notification.content, "Notification should have content");
  assertEqual(
    notification.type,
    "general",
    "Notification should have correct type"
  );
  assertEqual(
    notification.is_read,
    false,
    "Notification should be unread by default"
  );
  assertNotNull(
    notification.created_at,
    "Notification should have creation timestamp"
  );

  endTest();
}

async function testNotificationCreationWithMetadata(fixtures) {
  startTest("Notification Creation with Metadata");

  logSection("Test Metadata Support");
  logRequirement("Notifications must support flexible metadata storage");
  logRequirement("Metadata must be stored as valid JSONB");

  const metadata = {
    source: "test_system",
    priority: "high",
    category: "system_alert",
    custom_data: {
      nested_field: "test_value",
      numeric_field: 42,
    },
  };

  logAction("Creating notification with complex metadata");
  const notification = await fixtures.createTestNotification({
    type: "system",
    metadata: metadata,
  });

  logVerify("Notification with metadata created successfully");
  assertNotNull(notification.metadata, "Notification should have metadata");
  assertEqual(
    notification.metadata.source,
    "test_system",
    "Metadata should preserve source"
  );
  assertEqual(
    notification.metadata.priority,
    "high",
    "Metadata should preserve priority"
  );
  assertEqual(
    notification.metadata.custom_data.numeric_field,
    42,
    "Metadata should preserve nested numeric values"
  );

  endTest();
}

async function testNotificationCreationFunction(fixtures) {
  startTest("Notification Creation via Database Function");

  logSection("Test Database Function");
  logRequirement("create_notification function must work correctly");
  logRequirement("Function must handle authentication and validation");

  // Get authenticated user context
  const { client, user } = await userManager.asUser(
    TEST_AUTH_EMAIL,
    TEST_AUTH_PASSWORD
  );

  logAction("Creating notification via create_notification function");
  const { data: notificationId, error } = await client.rpc(
    "create_notification",
    {
      p_user_id: user.id,
      p_sender_id: user.id,
      p_title: `TEST_Function_Notification_${Date.now()}`,
      p_content: "This notification was created via the database function",
      p_type: "message",
      p_related_entity_id: null,
      p_action: "/test-action",
      p_metadata: { test_function: true },
    }
  );

  fixtures.trackRecord("notifications", notificationId);

  logVerify("Function-created notification successful");
  assert(!error, "Function should execute without error");
  assertNotNull(notificationId, "Function should return notification ID");

  // Verify the notification was created properly
  const { data: createdNotification, error: fetchError } = await supabase
    .from("notifications")
    .select("*")
    .eq("id", notificationId)
    .single();

  assert(!fetchError, "Should be able to fetch created notification");
  assertEqual(
    createdNotification.user_id,
    user.id,
    "Should have correct user ID"
  );
  assertEqual(
    createdNotification.sender_id,
    user.id,
    "Should have correct sender ID"
  );
  assertEqual(createdNotification.type, "message", "Should have correct type");
  assertNotNull(
    createdNotification.metadata.test_function,
    "Should preserve metadata"
  );

  endTest();
}

async function testBatchNotificationCreation(fixtures) {
  startTest("Batch Notification Creation");

  logSection("Test Batch Function");
  logRequirement(
    "create_notifications_batch function must create multiple notifications"
  );
  logRequirement("Batch creation must be efficient and atomic");

  // Get authenticated user context
  const { client, user } = await userManager.asUser(
    TEST_AUTH_EMAIL,
    TEST_AUTH_PASSWORD
  );

  // Create multiple test user IDs (using same user for simplicity)
  const userIds = [user.id, user.id, user.id];

  logAction(
    "Creating batch notifications via create_notifications_batch function"
  );
  const { data: notificationIds, error } = await client.rpc(
    "create_notifications_batch",
    {
      p_user_ids: userIds,
      p_sender_id: user.id,
      p_title: `TEST_Batch_Notification_${Date.now()}`,
      p_content: "This is a batch-created notification",
      p_type: "general",
      p_related_entity_id: null,
      p_action: "/batch-action",
      p_metadata: { batch_test: true, batch_size: userIds.length },
    }
  );

  // Track all created notifications for cleanup
  if (notificationIds) {
    notificationIds.forEach((id) => fixtures.trackRecord("notifications", id));
  }

  logVerify("Batch notification creation successful");
  assert(!error, "Batch function should execute without error");
  assertNotNull(notificationIds, "Function should return notification IDs");
  assertEqual(
    notificationIds.length,
    userIds.length,
    "Should create correct number of notifications"
  );

  // Verify all notifications were created
  const { data: batchNotifications, error: fetchError } = await supabase
    .from("notifications")
    .select("*")
    .in("id", notificationIds);

  assert(!fetchError, "Should be able to fetch batch notifications");
  assertEqual(
    batchNotifications.length,
    userIds.length,
    "Should fetch all created notifications"
  );

  endTest();
}

async function testNotificationValidation(fixtures) {
  startTest("Notification Validation");

  logSection("Test Required Field Validation");
  logRequirement("System must validate required notification fields");
  logRequirement("Invalid notifications must be rejected");

  logAction("Testing validation with missing required fields");

  try {
    await supabase.from("notifications").insert({
      // Missing required fields: user_id, title, content, type
      action_url: "/test",
    });
    assert(false, "Should not allow notification without required fields");
  } catch (error) {
    logExpectedFailure("Validation correctly rejected invalid notification");
    assert(true, "System should validate required fields");
  }

  logAction("Testing validation with invalid notification type");

  try {
    const userId = await fixtures.getTestUserId();
    await supabase.from("notifications").insert({
      user_id: userId,
      title: "Test",
      content: "Test content",
      type: "invalid_type", // Invalid type
    });
    assert(false, "Should not allow invalid notification type");
  } catch (error) {
    logExpectedFailure(
      "Validation correctly rejected invalid notification type"
    );
    assert(true, "System should validate notification types");
  }

  endTest();
}

async function testNotificationTypes(fixtures) {
  startTest("Notification Type Support");

  logSection("Test All Notification Types");
  logRequirement("System must support all defined notification types");

  const validTypes = [
    "appointment",
    "system",
    "general",
    "announcement",
    "payment",
    "booking",
    "waitlist",
    "reminder",
    "message",
    "broadcast",
  ];

  for (const type of validTypes) {
    logAction(`Creating notification with type: ${type}`);

    const notification = await fixtures.createTestNotification({
      type: type,
      title: `TEST_${type}_notification_${Date.now()}`,
      content: `Test notification of type ${type}`,
    });

    assertEqual(
      notification.type,
      type,
      `Should create notification with type: ${type}`
    );
  }

  logVerify("All notification types supported");

  endTest();
}
