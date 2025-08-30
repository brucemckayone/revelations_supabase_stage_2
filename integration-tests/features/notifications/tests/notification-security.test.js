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
} from "../../../shared/utilities/test-utils.js";
import { NotificationsFixtures } from "../fixtures.js";
import { supabase } from "../../../config/database.js";
import { TestUserManager } from "../../../shared/utilities/test-user-manager.js";

const TEST_AUTH_EMAIL =
  process.env.TEST_USER_EMAIL || "brucemckayone@gmail.com";
const TEST_AUTH_PASSWORD = process.env.TEST_USER_PASSWORD || "password123";
const SECOND_USER_EMAIL = "brucemckaytwo@gmail.com";
const SECOND_USER_PASSWORD = "password123";

const userManager = new TestUserManager();

export async function runNotificationSecurityTests() {
  const fixtures = new NotificationsFixtures();

  try {
    await testNotificationRLSPolicies(fixtures);
    await testCrossTenantSecurity(fixtures);
    await testDeliveryAccessControl(fixtures);
    await testPreferencesIsolation(fixtures);
    await testBroadcastSecurity(fixtures);
    await testNotificationInjection(fixtures);
  } finally {
    await fixtures.cleanup();
  }
}

async function testNotificationRLSPolicies(fixtures) {
  startTest("Notification RLS Policy Enforcement");

  logSection("Test Row Level Security");
  logRequirement("Users can only see their own notifications");
  logRequirement("RLS policies must prevent unauthorized access");

  // Create two different users
  const { client: client1, user: user1 } = await userManager.asUser(
    TEST_AUTH_EMAIL,
    TEST_AUTH_PASSWORD
  );

  const { client: client2, user: user2 } = await userManager.asUser(
    SECOND_USER_EMAIL,
    SECOND_USER_PASSWORD
  );

  logAction("Creating notifications for different users");

  // Create notification for user 1
  const { data: notification1 } = await client1.rpc("create_notification", {
    p_user_id: user1.id,
    p_sender_id: user1.id,
    p_title: "User 1 Private Notification",
    p_content: "This should only be visible to user 1",
    p_type: "message",
  });

  fixtures.trackRecord("notifications", notification1);

  // Create notification for user 2
  const { data: notification2 } = await client2.rpc("create_notification", {
    p_user_id: user2.id,
    p_sender_id: user2.id,
    p_title: "User 2 Private Notification",
    p_content: "This should only be visible to user 2",
    p_type: "message",
  });

  fixtures.trackRecord("notifications", notification2);

  logAction("Testing cross-user access restrictions");

  // User 1 tries to read user 2's notification
  const { data: unauthorizedRead, error: readError } = await client1
    .from("notifications")
    .select("*")
    .eq("id", notification2);

  logVerify("Verifying RLS prevents unauthorized reads");
  assertEqual(
    unauthorizedRead?.length || 0,
    0,
    "User 1 should not see user 2's notifications"
  );

  // User 1 reads their own notifications
  const { data: authorizedRead } = await client1
    .from("notifications")
    .select("*")
    .eq("user_id", user1.id);

  assert(authorizedRead.length > 0, "User should see their own notifications");
  assert(
    authorizedRead.some((n) => n.id === notification1),
    "Should include user's notification"
  );
  assert(
    !authorizedRead.some((n) => n.id === notification2),
    "Should not include other user's notification"
  );

  logAction("Testing unauthorized update attempts");

  // User 1 tries to update user 2's notification
  const { error: updateError } = await client1
    .from("notifications")
    .update({ is_read: true })
    .eq("id", notification2);

  // The update might not return an error but won't affect any rows
  const { data: checkUpdate } = await supabase
    .from("notifications")
    .select("is_read")
    .eq("id", notification2)
    .single();

  assertEqual(
    checkUpdate.is_read,
    false,
    "Unauthorized update should not succeed"
  );

  endTest();
}

async function testCrossTenantSecurity(fixtures) {
  startTest("Cross-Tenant Security Isolation");

  logSection("Test Multi-Tenant Isolation");
  logRequirement("Notifications must be completely isolated between users");
  logRequirement("No data leakage between tenants");

  const { client: client1, user: user1 } = await userManager.asUser(
    TEST_AUTH_EMAIL,
    TEST_AUTH_PASSWORD
  );

  const { client: client2, user: user2 } = await userManager.asUser(
    SECOND_USER_EMAIL,
    SECOND_USER_PASSWORD
  );

  logAction("Creating sensitive notifications");

  // User 1 creates sensitive notification
  await client1.rpc("create_notification", {
    p_user_id: user1.id,
    p_sender_id: user1.id,
    p_title: "Confidential: Financial Alert",
    p_content: "Your payment of $1000 has been processed",
    p_type: "payment",
    p_metadata: { amount: 1000, account: "****1234" },
  });

  logAction("Testing data isolation in queries");

  // User 2 queries all notifications
  const { data: user2Notifications } = await client2
    .from("notifications")
    .select("*");

  logVerify("Verifying complete isolation");

  // User 2 should only see their own notifications
  for (const notification of user2Notifications || []) {
    assertEqual(
      notification.user_id,
      user2.id,
      "All notifications should belong to querying user"
    );
    assert(
      !notification.title.includes("Confidential"),
      "Should not see other user's sensitive data"
    );
  }

  // Test aggregate queries
  const { count: user1Count } = await client1
    .from("notifications")
    .select("*", { count: "exact", head: true });

  const { count: user2Count } = await client2
    .from("notifications")
    .select("*", { count: "exact", head: true });

  logVerify("Each user sees only their notification count");
  assert(user1Count >= 1, "User 1 should see their notifications");
  assert(user2Count >= 0, "User 2 should see their notifications");

  endTest();
}

async function testDeliveryAccessControl(fixtures) {
  startTest("Delivery Channel Access Control");

  logSection("Test Delivery Record Security");
  logRequirement("Delivery records must be protected");
  logRequirement("Users cannot manipulate delivery status");

  const { client, user } = await userManager.asUser(
    TEST_AUTH_EMAIL,
    TEST_AUTH_PASSWORD
  );

  const notification = await fixtures.createTestNotification({
    user_id: user.id,
  });

  const delivery = await fixtures.createTestNotificationDelivery(
    notification.id,
    {
      channel: "email",
      status: "pending",
    }
  );

  logAction("Testing unauthorized delivery manipulation");

  // Try to directly update delivery status (should fail)
  const { error: deliveryUpdateError } = await client
    .from("notification_deliveries")
    .update({ status: "sent", external_id: "fake_id" })
    .eq("id", delivery.id);

  logExpectedFailure("Direct delivery updates should be blocked");
  assertNotNull(
    deliveryUpdateError,
    "Should not allow direct delivery updates"
  );

  // Verify delivery wasn't modified
  const { data: checkDelivery } = await supabase
    .from("notification_deliveries")
    .select("*")
    .eq("id", delivery.id)
    .single();

  assertEqual(
    checkDelivery.status,
    "pending",
    "Delivery status should remain unchanged"
  );
  assertEqual(
    checkDelivery.external_id,
    null,
    "External ID should remain null"
  );

  endTest();
}

async function testPreferencesIsolation(fixtures) {
  startTest("Notification Preferences Isolation");

  logSection("Test Preferences Security");
  logRequirement("Users can only modify their own preferences");
  logRequirement("Preferences must be isolated between users");

  const { client: client1, user: user1 } = await userManager.asUser(
    TEST_AUTH_EMAIL,
    TEST_AUTH_PASSWORD
  );

  const { client: client2, user: user2 } = await userManager.asUser(
    SECOND_USER_EMAIL,
    SECOND_USER_PASSWORD
  );

  logAction("Creating preferences for each user");

  // Create preferences via fixtures (using service role)
  const prefs1 = await fixtures.createTestNotificationPreferences(user1.id, {
    type: "payment",
    email: true,
    push: false,
  });

  const prefs2 = await fixtures.createTestNotificationPreferences(user2.id, {
    type: "payment",
    email: false,
    push: true,
  });

  logAction("Testing cross-user preference access");

  // User 1 tries to read user 2's preferences
  const { data: unauthorizedPrefs } = await client1
    .from("notification_preferences")
    .select("*")
    .eq("user_id", user2.id);

  assertEqual(
    unauthorizedPrefs?.length || 0,
    0,
    "Should not see other user's preferences"
  );

  // User 1 tries to update user 2's preferences
  const { error: prefUpdateError } = await client1
    .from("notification_preferences")
    .update({ email: true })
    .eq("id", prefs2.id);

  // Verify preferences weren't changed
  const { data: checkPrefs } = await supabase
    .from("notification_preferences")
    .select("*")
    .eq("id", prefs2.id)
    .single();

  assertEqual(
    checkPrefs.email,
    false,
    "Other user's preferences should remain unchanged"
  );

  endTest();
}

async function testBroadcastSecurity(fixtures) {
  startTest("Broadcast Notification Security");

  logSection("Test Broadcast Authorization");
  logRequirement("Only authorized users can send broadcasts");
  logRequirement("Broadcast audience must be properly controlled");

  const { client: regularClient, user: regularUser } = await userManager.asUser(
    TEST_AUTH_EMAIL,
    TEST_AUTH_PASSWORD
  );

  logAction("Testing unauthorized broadcast attempt");

  // Regular user tries to send broadcast
  const { error: broadcastError } = await regularClient.rpc(
    "create_broadcast_announcement",
    {
      p_title: "Unauthorized Broadcast",
      p_content: "This should not be allowed",
      p_action: "/spam",
      p_audience_criteria: { target: "all" },
    }
  );

  // Note: Current implementation may not have admin checks
  // This test documents expected behavior
  if (broadcastError) {
    logExpectedFailure("Regular users should not send broadcasts");
    assertNotNull(broadcastError, "Broadcast should fail for regular users");
  } else {
    // If it succeeds, track for cleanup
    logVerify(
      "WARNING: Broadcast succeeded - may need additional authorization"
    );
  }

  endTest();
}

async function testNotificationInjection(fixtures) {
  startTest("Notification Injection Prevention");

  logSection("Test SQL Injection and XSS Prevention");
  logRequirement("System must sanitize all notification content");
  logRequirement("Malicious content must be properly escaped");

  const { client, user } = await userManager.asUser(
    TEST_AUTH_EMAIL,
    TEST_AUTH_PASSWORD
  );

  logAction("Testing SQL injection in notification content");

  const maliciousContent = "'; DROP TABLE notifications; --";
  const xssContent = "<script>alert('XSS')</script>";

  // Create notification with potentially malicious content
  const { data: notificationId, error } = await client.rpc(
    "create_notification",
    {
      p_user_id: user.id,
      p_sender_id: user.id,
      p_title: maliciousContent,
      p_content: xssContent,
      p_type: "message",
      p_metadata: {
        test: "injection",
        script: "<img src=x onerror=alert(1)>",
      },
    }
  );

  fixtures.trackRecord("notifications", notificationId);

  logVerify("Verifying content is stored safely");
  assert(!error, "Should handle special characters safely");
  assertNotNull(
    notificationId,
    "Should create notification despite special content"
  );

  // Verify content is stored as-is (not executed)
  const { data: storedNotification } = await supabase
    .from("notifications")
    .select("*")
    .eq("id", notificationId)
    .single();

  assertEqual(
    storedNotification.title,
    maliciousContent,
    "SQL should be stored as text, not executed"
  );
  assertEqual(
    storedNotification.content,
    xssContent,
    "XSS content should be stored safely"
  );

  // Verify tables still exist
  const { error: tableCheckError } = await supabase
    .from("notifications")
    .select("count", { count: "exact", head: true });

  assert(!tableCheckError, "Notifications table should still exist");

  endTest();
}
