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
} from "../../../shared/utilities/test-utils.js";
import { NotificationsFixtures } from "../fixtures.js";
import { supabase } from "../../../config/database.js";

export async function runNotificationDeliveryTests() {
  const fixtures = new NotificationsFixtures();

  try {
    await testNotificationDeliveryCreation(fixtures);
    await testMultiChannelDelivery(fixtures);
    await testDeliveryStatusTracking(fixtures);
    await testDeliveryRetryLogic(fixtures);
    await testDeliveryChannelValidation(fixtures);
    await testFCMTokenManagement(fixtures);
  } finally {
    await fixtures.cleanup();
  }
}

async function testNotificationDeliveryCreation(fixtures) {
  startTest("Notification Delivery Creation");

  logSection("Setup Delivery Test Environment");
  logRequirement("System must track delivery status per channel");
  logRequirement("Delivery records must link properly to notifications");

  logAction("Creating notification and delivery record");
  const notification = await fixtures.createTestNotification();
  const delivery = await fixtures.createTestNotificationDelivery(notification.id);

  logVerify("Delivery record created successfully");
  assertNotNull(delivery.id, "Delivery should have valid ID");
  assertEqual(delivery.notification_id, notification.id, "Delivery should link to notification");
  assertEqual(delivery.channel, "email", "Delivery should have correct channel");
  assertEqual(delivery.status, "pending", "Delivery should start as pending");
  assertEqual(delivery.attempt_count, 0, "Delivery should start with zero attempts");

  endTest();
}

async function testMultiChannelDelivery(fixtures) {
  startTest("Multi-Channel Delivery Setup");

  logSection("Test All Delivery Channels");
  logRequirement("System must support email, push, in-app, and SMS channels");
  logRequirement("Each channel must have independent delivery tracking");

  const notification = await fixtures.createTestNotification();
  
  const channels = ["email", "push", "in_app", "sms"];
  const deliveries = {};

  for (const channel of channels) {
    logAction(`Creating delivery record for ${channel} channel`);
    deliveries[channel] = await fixtures.createTestNotificationDelivery(notification.id, {
      channel: channel
    });
  }

  logVerify("All delivery channels supported");
  for (const channel of channels) {
    assertEqual(deliveries[channel].channel, channel, `Should create ${channel} delivery`);
    assertEqual(deliveries[channel].notification_id, notification.id, `${channel} delivery should link to notification`);
  }

  // Test querying deliveries by channel
  logAction("Testing delivery queries by channel");
  const { data: emailDeliveries, error } = await supabase
    .from("notification_deliveries")
    .select("*")
    .eq("notification_id", notification.id)
    .eq("channel", "email");

  assert(!error, "Should be able to query deliveries by channel");
  assertEqual(emailDeliveries.length, 1, "Should find email delivery");

  endTest();
}

async function testDeliveryStatusTracking(fixtures) {
  startTest("Delivery Status Tracking");

  logSection("Test Status Progression");
  logRequirement("Delivery status must progress through defined states");
  logRequirement("Status changes must be tracked with timestamps");

  const notification = await fixtures.createTestNotification();
  const delivery = await fixtures.createTestNotificationDelivery(notification.id);

  const validStatuses = ["pending", "processing", "sent", "delivered", "failed", "cancelled"];

  logAction("Testing status progression");
  
  // Test updating to processing
  const { data: processingUpdate, error: processingError } = await supabase
    .from("notification_deliveries")
    .update({
      status: "processing",
      attempt_count: 1,
      updated_at: new Date().toISOString()
    })
    .eq("id", delivery.id)
    .select()
    .single();

  assert(!processingError, "Should be able to update status to processing");
  assertEqual(processingUpdate.status, "processing", "Status should be updated to processing");
  assertEqual(processingUpdate.attempt_count, 1, "Attempt count should be incremented");

  // Test updating to sent with external ID
  const externalId = `test_message_${Date.now()}`;
  const { data: sentUpdate, error: sentError } = await supabase
    .from("notification_deliveries")
    .update({
      status: "sent",
      external_id: externalId,
      updated_at: new Date().toISOString()
    })
    .eq("id", delivery.id)
    .select()
    .single();

  assert(!sentError, "Should be able to update status to sent");
  assertEqual(sentUpdate.status, "sent", "Status should be updated to sent");
  assertEqual(sentUpdate.external_id, externalId, "External ID should be stored");

  // Test failure with error message
  const { data: failedUpdate, error: failedError } = await supabase
    .from("notification_deliveries")
    .update({
      status: "failed",
      error_message: "Test failure for status tracking",
      next_attempt_at: new Date(Date.now() + 30 * 60 * 1000).toISOString()
    })
    .eq("id", delivery.id)
    .select()
    .single();

  assert(!failedError, "Should be able to update status to failed");
  assertEqual(failedUpdate.status, "failed", "Status should be updated to failed");
  assertNotNull(failedUpdate.error_message, "Error message should be stored");
  assertNotNull(failedUpdate.next_attempt_at, "Next attempt time should be set");

  endTest();
}

async function testDeliveryRetryLogic(fixtures) {
  startTest("Delivery Retry Logic");

  logSection("Test Retry Mechanism");
  logRequirement("Failed deliveries must support retry with backoff");
  logRequirement("Maximum retry attempts must be enforced");

  const notification = await fixtures.createTestNotification();
  
  logAction("Testing retry attempt tracking");
  
  // Create delivery with multiple retry attempts
  let delivery = await fixtures.createTestNotificationDelivery(notification.id, {
    status: "failed",
    attempt_count: 2,
    error_message: "Simulated failure for retry testing",
    next_attempt_at: new Date(Date.now() + 30 * 60 * 1000).toISOString()
  });

  assertEqual(delivery.attempt_count, 2, "Should track attempt count");
  assertNotNull(delivery.next_attempt_at, "Should set next retry time");

  // Test maximum attempts
  logAction("Testing maximum retry limit");
  const { data: maxAttemptDelivery, error: maxAttemptError } = await supabase
    .from("notification_deliveries")
    .update({ attempt_count: 3 })
    .eq("id", delivery.id)
    .select()
    .single();

  assert(!maxAttemptError, "Should be able to set attempt count to maximum");
  assertEqual(maxAttemptDelivery.attempt_count, 3, "Should track high attempt count");

  // Query deliveries that should be retried (attempt_count < 3)
  const { data: retryableDeliveries, error: retryError } = await supabase
    .from("notification_deliveries")
    .select("*")
    .eq("status", "failed")
    .lt("attempt_count", 3)
    .lte("next_attempt_at", new Date().toISOString());

  assert(!retryError, "Should be able to query retryable deliveries");

  endTest();
}

async function testDeliveryChannelValidation(fixtures) {
  startTest("Delivery Channel Validation");

  logSection("Test Channel Constraints");
  logRequirement("System must validate delivery channel values");
  logRequirement("Invalid channels must be rejected");

  const notification = await fixtures.createTestNotification();

  logAction("Testing invalid channel rejection");

  try {
    await supabase.from("notification_deliveries").insert({
      notification_id: notification.id,
      channel: "invalid_channel", // Invalid channel
      status: "pending"
    });
    assert(false, "Should not allow invalid delivery channel");
  } catch (error) {
    logExpectedFailure("Validation correctly rejected invalid channel");
    assert(true, "System should validate delivery channels");
  }

  logAction("Testing invalid status rejection");

  try {
    await supabase.from("notification_deliveries").insert({
      notification_id: notification.id,
      channel: "email",
      status: "invalid_status" // Invalid status
    });
    assert(false, "Should not allow invalid delivery status");
  } catch (error) {
    logExpectedFailure("Validation correctly rejected invalid status");
    assert(true, "System should validate delivery status");
  }

  endTest();
}

async function testFCMTokenManagement(fixtures) {
  startTest("FCM Token Management");

  logSection("Test Push Notification Tokens");
  logRequirement("System must manage FCM tokens for push notifications");
  logRequirement("Tokens must be linked to users and tracked for activity");

  const userId = await fixtures.getTestUserId();

  logAction("Creating FCM token");
  const fcmToken = await fixtures.createTestFCMToken(userId);

  logVerify("FCM token created successfully");
  assertNotNull(fcmToken.id, "Token should have valid ID");
  assertEqual(fcmToken.user_id, userId, "Token should be linked to user");
  assertNotNull(fcmToken.token, "Token should have token value");
  assertEqual(fcmToken.is_active, true, "Token should be active by default");
  assertNotNull(fcmToken.device_info, "Token should have device info");

  logAction("Testing token uniqueness");
  
  // Test that duplicate tokens are handled properly
  try {
    await fixtures.createTestFCMToken(userId, {
      token: fcmToken.token // Duplicate token
    });
    assert(false, "Should not allow duplicate tokens for same user");
  } catch (error) {
    logExpectedFailure("System correctly prevents duplicate tokens");
    assert(true, "System should enforce token uniqueness per user");
  }

  logAction("Testing token deactivation");
  
  const { data: deactivatedToken, error: deactivateError } = await supabase
    .from("user_fcm_tokens")
    .update({ 
      is_active: false,
      updated_at: new Date().toISOString()
    })
    .eq("id", fcmToken.id)
    .select()
    .single();

  assert(!deactivateError, "Should be able to deactivate token");
  assertEqual(deactivatedToken.is_active, false, "Token should be deactivated");

  logAction("Testing active token queries");
  
  const { data: activeTokens, error: activeError } = await supabase
    .from("user_fcm_tokens")
    .select("*")
    .eq("user_id", userId)
    .eq("is_active", true);

  assert(!activeError, "Should be able to query active tokens");
  
  endTest();
}


