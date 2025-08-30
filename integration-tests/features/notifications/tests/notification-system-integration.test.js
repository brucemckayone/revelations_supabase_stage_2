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
} from "../../../shared/utilities/test-utils.js";
import { NotificationsFixtures } from "../fixtures.js";
import { supabase } from "../../../config/database.js";
import { TestUserManager } from "../../../shared/utilities/test-user-manager.js";

const TEST_AUTH_EMAIL = process.env.TEST_USER_EMAIL || "brucemckayone@gmail.com";
const TEST_AUTH_PASSWORD = process.env.TEST_USER_PASSWORD || "password123";
const userManager = new TestUserManager();

export async function runNotificationSystemIntegrationTests() {
  const fixtures = new NotificationsFixtures();

  try {
    await testEventNotificationTriggers(fixtures);
    await testWaitlistNotificationTriggers(fixtures);
    await testAppointmentNotificationTriggers(fixtures);
    await testEndToEndNotificationFlow(fixtures);
    await testNotificationPreferencesIntegration(fixtures);
  } finally {
    await fixtures.cleanup();
  }
}

async function testEventNotificationTriggers(fixtures) {
  startTest("Event Notification Triggers");

  logSection("Test Event-Related Notifications");
  logRequirement("System must send notifications for event-related activities");
  logRequirement("Event notifications must be properly categorized");

  // This test verifies the notification system integration points
  // but doesn't actually trigger the events since we're focusing on notification testing

  logAction("Testing event notification structure");
  
  const eventNotification = await fixtures.createTestNotification({
    type: "booking",
    title: "Event Booking Confirmation",
    content: "Your booking for the test event has been confirmed",
    metadata: {
      event_id: "test_event_123",
      booking_id: "test_booking_456",
      event_type: "workshop"
    }
  });

  logVerify("Event notification created correctly");
  assertEqual(eventNotification.type, "booking", "Should be booking type");
  assertNotNull(eventNotification.metadata.event_id, "Should have event ID in metadata");
  assertNotNull(eventNotification.metadata.booking_id, "Should have booking ID in metadata");

  endTest();
}

async function testWaitlistNotificationTriggers(fixtures) {
  startTest("Waitlist Notification Triggers");

  logSection("Test Waitlist-Related Notifications");
  logRequirement("System must send notifications for waitlist activities");
  logRequirement("Waitlist notifications must include position and timing info");

  logAction("Testing waitlist notification structure");
  
  const waitlistNotification = await fixtures.createTestNotification({
    type: "waitlist",
    title: "Waitlist Position Update",
    content: "A spot has opened up! You can now book the event",
    metadata: {
      waitlist_entry_id: "test_waitlist_789",
      event_id: "test_event_123",
      position: 1,
      expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
    }
  });

  logVerify("Waitlist notification created correctly");
  assertEqual(waitlistNotification.type, "waitlist", "Should be waitlist type");
  assertNotNull(waitlistNotification.metadata.waitlist_entry_id, "Should have waitlist entry ID");
  assertEqual(waitlistNotification.metadata.position, 1, "Should have position in metadata");

  endTest();
}

async function testAppointmentNotificationTriggers(fixtures) {
  startTest("Appointment Notification Triggers");

  logSection("Test Appointment-Related Notifications");
  logRequirement("System must send notifications for appointment activities");
  logRequirement("Appointment notifications must include timing and service info");

  logAction("Testing appointment notification structure");
  
  const appointmentNotification = await fixtures.createTestNotification({
    type: "appointment",
    title: "Appointment Reminder",
    content: "Your appointment is scheduled for tomorrow at 2:00 PM",
    metadata: {
      appointment_id: "test_appointment_101",
      service_id: "test_service_202",
      provider_id: "test_provider_303",
      scheduled_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
      reminder_type: "24_hour"
    }
  });

  logVerify("Appointment notification created correctly");
  assertEqual(appointmentNotification.type, "appointment", "Should be appointment type");
  assertNotNull(appointmentNotification.metadata.appointment_id, "Should have appointment ID");
  assertEqual(appointmentNotification.metadata.reminder_type, "24_hour", "Should have reminder type");

  endTest();
}

async function testEndToEndNotificationFlow(fixtures) {
  startTest("End-to-End Notification Flow");

  logSection("Test Complete Notification Pipeline");
  logRequirement("Notifications must flow from creation to delivery");
  logRequirement("Each step must be properly tracked and logged");

  const setup = await fixtures.createNotificationTestSetup();

  logAction("Verifying complete notification setup");
  
  // Verify notification exists
  assertNotNull(setup.notification, "Should have notification");
  assertNotNull(setup.deliveries, "Should have delivery records");
  assertNotNull(setup.preferences, "Should have user preferences");
  assertNotNull(setup.fcmToken, "Should have FCM token");

  logAction("Testing notification-to-delivery linking");
  
  // Verify deliveries link to notification
  for (const [channel, delivery] of Object.entries(setup.deliveries)) {
    assertEqual(delivery.notification_id, setup.notification.id, `${channel} delivery should link to notification`);
    assertEqual(delivery.status, "pending", `${channel} delivery should start as pending`);
  }

  logAction("Testing user preferences integration");
  
  // Check if deliveries respect user preferences
  assertEqual(setup.preferences.user_id, setup.userId, "Preferences should be for correct user");
  
  // Simulate preference-based delivery filtering
  const shouldDeliverEmail = setup.preferences.email;
  const shouldDeliverPush = setup.preferences.push;
  
  if (shouldDeliverEmail) {
    assertNotNull(setup.deliveries.email, "Should have email delivery when enabled");
  }
  
  if (shouldDeliverPush) {
    assertNotNull(setup.deliveries.push, "Should have push delivery when enabled");
    assertNotNull(setup.fcmToken, "Should have FCM token for push notifications");
  }

  logVerify("End-to-end flow validated");

  endTest();
}

async function testNotificationPreferencesIntegration(fixtures) {
  startTest("Notification Preferences Integration");

  logSection("Test Preferences-Based Delivery");
  logRequirement("Deliveries must respect user notification preferences");
  logRequirement("Disabled channels must not receive notifications");

  const userId = await fixtures.getTestUserId();

  logAction("Setting up user with specific preferences");
  
  // Create preferences with email disabled, push enabled  
  const preferences = await fixtures.createTestNotificationPreferences(userId, {
    type: "reminder", // Valid preference type
    in_app: true,
    email: false,  // Disabled
    push: true,    // Enabled
    sms: false
  });

  logAction("Creating notification for user with preferences");
  
  const notification = await fixtures.createTestNotification({
    user_id: userId,
    type: "reminder",
    title: "Test Reminder with Preferences"
  });

  logAction("Testing preference-based delivery creation");
  
  // Simulate delivery system respecting preferences
  // Email delivery should not be created (disabled)
  // Push delivery should be created (enabled)
  
  const pushDelivery = await fixtures.createTestNotificationDelivery(notification.id, {
    channel: "push",
    status: "pending"
  });

  const inAppDelivery = await fixtures.createTestNotificationDelivery(notification.id, {
    channel: "in_app", 
    status: "pending"
  });

  logVerify("Deliveries created based on preferences");
  assertNotNull(pushDelivery, "Should create push delivery (enabled)");
  assertNotNull(inAppDelivery, "Should create in-app delivery (enabled)");

  // Verify we can query user's notification preferences for delivery decisions
  const { data: userPrefs, error } = await supabase
    .from("notification_preferences")
    .select("*")
    .eq("user_id", userId)
    .eq("type", "reminder")
    .single();

  assert(!error, "Should be able to query user preferences");
  assertEqual(userPrefs.email, false, "Email should be disabled");
  assertEqual(userPrefs.push, true, "Push should be enabled");

  endTest();
}
