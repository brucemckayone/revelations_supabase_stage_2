import {
  startTest,
  endTest,
  logSection,
  logRequirement,
  logAction,
  logVerify,
  assert,
  assertEqual,
  assertNotNull,
  assertGreaterThan,
} from "../../../shared/utilities/test-utils.js";
import { NotificationsFixtures } from "../fixtures.js";
import { supabase } from "../../../config/database.js";
import { TestUserManager } from "../../../shared/utilities/test-user-manager.js";

const TEST_AUTH_EMAIL =
  process.env.TEST_USER_EMAIL || "brucemckayone@gmail.com";
const TEST_AUTH_PASSWORD = process.env.TEST_USER_PASSWORD || "password123";
const userManager = new TestUserManager();

export async function runNotificationBroadcastTests() {
  const fixtures = new NotificationsFixtures();

  try {
    await testBroadcastAnnouncementCreation(fixtures);
    await testBroadcastToAllUsers(fixtures);
    await testBroadcastWithCriteria(fixtures);
    await testBroadcastDeliveryTracking(fixtures);
  } finally {
    await fixtures.cleanup();
  }
}

async function testBroadcastAnnouncementCreation(fixtures) {
  startTest("Broadcast Announcement Creation");

  logSection("Setup Broadcast Environment");
  logRequirement("System must support broadcast announcements");
  logRequirement("Broadcasts must be created with proper metadata");

  const { client, user } = await userManager.asUser(
    TEST_AUTH_EMAIL,
    TEST_AUTH_PASSWORD
  );

  logAction("Creating broadcast announcement");
  const { data: broadcastId, error } = await client.rpc(
    "create_broadcast_announcement",
    {
      p_title: `TEST_Broadcast_${Date.now()}`,
      p_content: "This is a test broadcast announcement",
      p_action: "/broadcast-action",
      p_audience_criteria: { test_broadcast: true },
    }
  );

  fixtures.trackRecord("notifications", broadcastId);

  logVerify("Broadcast created successfully");
  if (error) {
    console.log("Broadcast error:", error);
    console.log("Broadcast data:", broadcastId);
  }
  assert(
    !error,
    `Broadcast function should execute without error: ${
      error?.message || "Unknown error"
    }`
  );
  assertNotNull(broadcastId, "Function should return broadcast ID");

  // Verify the broadcast notification
  const { data: broadcast, error: fetchError } = await supabase
    .from("notifications")
    .select("*")
    .eq("id", broadcastId)
    .single();

  assert(!fetchError, "Should be able to fetch broadcast");
  assertEqual(broadcast.type, "broadcast", "Should be broadcast type");
  assertEqual(broadcast.sender_id, user.id, "Should have correct sender");
  assertNotNull(broadcast.audience_criteria, "Should have audience criteria");

  endTest();
}

async function testBroadcastToAllUsers(fixtures) {
  startTest("Broadcast to All Users");

  logSection("Test System-Wide Broadcasts");
  logRequirement("System must support broadcasting to all users");
  logRequirement("All active users must receive broadcast notifications");

  const { client, user } = await userManager.asUser(
    TEST_AUTH_EMAIL,
    TEST_AUTH_PASSWORD
  );

  logAction("Creating system-wide broadcast");
  const { data: broadcastIds, error } = await client.rpc(
    "create_notification_for_all_users",
    {
      p_title: `TEST_SystemBroadcast_${Date.now()}`,
      p_content: "System-wide announcement for all users",
      p_type: "announcement",
      p_action: "/system-announcement",
    }
  );

  if (broadcastIds && Array.isArray(broadcastIds)) {
    broadcastIds.forEach((id) => fixtures.trackRecord("notifications", id));
  }

  logVerify("System broadcast created");
  assert(!error, "System broadcast should execute without error");
  assertNotNull(broadcastIds, "Should return notification IDs");

  endTest();
}

async function testBroadcastWithCriteria(fixtures) {
  startTest("Broadcast with Audience Criteria");

  logSection("Test Targeted Broadcasts");
  logRequirement("Broadcasts must support audience targeting");
  logRequirement("Criteria must filter recipients appropriately");

  const { client } = await userManager.asUser(
    TEST_AUTH_EMAIL,
    TEST_AUTH_PASSWORD
  );

  logAction("Creating targeted broadcast");
  const audienceCriteria = {
    user_type: "premium",
    region: "test_region",
    active_since: "2024-01-01",
  };

  const { data: targetedBroadcastId, error } = await client.rpc(
    "create_broadcast_announcement",
    {
      p_title: `TEST_TargetedBroadcast_${Date.now()}`,
      p_content: "This broadcast targets specific user criteria",
      p_action: "/targeted-action",
      p_audience_criteria: audienceCriteria,
    }
  );

  fixtures.trackRecord("notifications", targetedBroadcastId);

  logVerify("Targeted broadcast created");
  assert(!error, "Targeted broadcast should execute without error");
  assertNotNull(targetedBroadcastId, "Should return broadcast ID");

  // Verify criteria were stored
  const { data: targetedBroadcast, error: fetchError } = await supabase
    .from("notifications")
    .select("*")
    .eq("id", targetedBroadcastId)
    .single();

  assert(!fetchError, "Should fetch targeted broadcast");
  assertEqual(
    targetedBroadcast.audience_criteria.user_type,
    "premium",
    "Should preserve audience criteria"
  );

  endTest();
}

async function testBroadcastDeliveryTracking(fixtures) {
  startTest("Broadcast Delivery Tracking");

  logSection("Test Broadcast Delivery Management");
  logRequirement("Broadcast deliveries must be tracked per recipient");
  logRequirement("Delivery status must be maintained for each channel");

  const notification = await fixtures.createTestNotification({
    type: "broadcast",
    audience_type: "all",
  });

  logAction("Creating delivery records for broadcast");

  // Create multiple delivery records to simulate broadcast
  const channels = ["email", "push", "in_app"];
  const deliveries = [];

  for (const channel of channels) {
    const delivery = await fixtures.createTestNotificationDelivery(
      notification.id,
      {
        channel: channel,
        status: "pending",
      }
    );
    deliveries.push(delivery);
  }

  logVerify("Broadcast delivery records created");
  assertEqual(
    deliveries.length,
    channels.length,
    "Should create delivery for each channel"
  );

  logAction("Testing broadcast delivery status updates");

  // Simulate processing broadcast deliveries
  for (const delivery of deliveries) {
    const { data: updatedDelivery, error } = await supabase
      .from("notification_deliveries")
      .update({
        status: "sent",
        external_id: `broadcast_${delivery.channel}_${Date.now()}`,
        updated_at: new Date().toISOString(),
      })
      .eq("id", delivery.id)
      .select()
      .single();

    assert(!error, `Should update ${delivery.channel} delivery status`);
    assertEqual(
      updatedDelivery.status,
      "sent",
      `${delivery.channel} delivery should be sent`
    );
  }

  logAction("Querying broadcast delivery status");

  const { data: broadcastDeliveries, error: queryError } = await supabase
    .from("notification_deliveries")
    .select("*")
    .eq("notification_id", notification.id)
    .eq("status", "sent");

  assert(!queryError, "Should query broadcast deliveries");
  assertEqual(
    broadcastDeliveries.length,
    channels.length,
    "All deliveries should be sent"
  );

  endTest();
}
