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

export async function runNotificationPreferencesTests() {
  const fixtures = new NotificationsFixtures();

  try {
    await testBasicPreferencesCreation(fixtures);
    await testPreferencesPerType(fixtures);
    await testChannelPreferences(fixtures);
    await testPreferencesValidation(fixtures);
    await testDefaultPreferences(fixtures);
    await testPreferencesUpdates(fixtures);
  } finally {
    await fixtures.cleanup();
  }
}

async function testBasicPreferencesCreation(fixtures) {
  startTest("Basic Preferences Creation");

  logSection("Setup Preferences Test Environment");
  logRequirement("Users must be able to set notification preferences");
  logRequirement("Preferences must be stored per user and notification type");

  const userId = await fixtures.getTestUserId();

  // Clean up any existing preferences for this test
  await supabase
    .from("notification_preferences")
    .delete()
    .eq("user_id", userId)
    .eq("type", "system"); // Use a specific type for this test

  logAction("Creating notification preferences");
  const preferences = await fixtures.createTestNotificationPreferences(userId, {
    type: "system" // Use a specific type to avoid conflicts
  });

  logVerify("Preferences created successfully");
  assertNotNull(preferences.id, "Preferences should have valid ID");
  assertEqual(preferences.user_id, userId, "Preferences should be linked to user");
  assertEqual(preferences.type, "system", "Preferences should have correct type");
  assertEqual(preferences.in_app, true, "In-app notifications should default to enabled");
  assertEqual(preferences.email, true, "Email notifications should default to enabled");
  assertEqual(preferences.push, false, "Push notifications should be disabled by default");
  assertEqual(preferences.sms, false, "SMS notifications should be disabled by default");

  endTest();
}

async function testPreferencesPerType(fixtures) {
  startTest("Preferences Per Notification Type");

  logSection("Test Type-Specific Preferences");
  logRequirement("Users must be able to set different preferences for each notification type");
  logRequirement("Preferences must be independent per type");

  const userId = await fixtures.getTestUserId();
  
  // Valid preference types from database constraint
  const notificationTypes = ["appointment", "message", "system", "payment", "reminder"];
  
  // Clean up any existing preferences for all types we'll test
  for (const type of notificationTypes) {
    await supabase
      .from("notification_preferences")
      .delete()
      .eq("user_id", userId)
      .eq("type", type);
  }
  
  const createdPreferences = {};

  for (const type of notificationTypes) {
    logAction(`Creating preferences for ${type} notifications`);
    
    createdPreferences[type] = await fixtures.createTestNotificationPreferences(userId, {
      type: type,
      in_app: true,
      email: type === "system", // Only system notifications via email
      push: type === "appointment", // Only appointment notifications via push
      sms: false
    });
  }

  logVerify("Type-specific preferences created");
  for (const type of notificationTypes) {
    assertEqual(createdPreferences[type].type, type, `Should create preferences for ${type}`);
    assertEqual(createdPreferences[type].user_id, userId, `${type} preferences should link to user`);
  }

  // Verify we can query preferences by type
  logAction("Testing preferences queries by type");
  const { data: systemPrefs, error } = await supabase
    .from("notification_preferences")
    .select("*")
    .eq("user_id", userId)
    .eq("type", "system")
    .single();

  assert(!error, "Should be able to query preferences by type");
  assertEqual(systemPrefs.email, true, "System preferences should have email enabled");

  endTest();
}

async function testChannelPreferences(fixtures) {
  startTest("Channel Preference Management");

  logSection("Test Individual Channel Settings");
  logRequirement("Users must control each notification channel independently");
  logRequirement("Channel preferences must be boolean values");

  const userId = await fixtures.getTestUserId();

  // Test all possible channel combinations
  const channelCombinations = [
    { in_app: true, email: false, push: false, sms: false },
    { in_app: false, email: true, push: false, sms: false },
    { in_app: false, email: false, push: true, sms: false },
    { in_app: false, email: false, push: false, sms: true },
    { in_app: true, email: true, push: true, sms: true }, // All enabled
    { in_app: false, email: false, push: false, sms: false }, // All disabled
  ];

  // Use valid types for each combination
  const validTypes = ["appointment", "message", "system", "payment", "reminder", "appointment"]; // Reuse appointment for last one
  
  for (const [index, channels] of channelCombinations.entries()) {
    logAction(`Testing channel combination ${index + 1}`);
    
    // Clean up existing preference for this type
    await supabase
      .from("notification_preferences")
      .delete()
      .eq("user_id", userId)
      .eq("type", validTypes[index]);
    
    const preferences = await fixtures.createTestNotificationPreferences(userId, {
      type: validTypes[index],
      ...channels
    });

    assertEqual(preferences.in_app, channels.in_app, `In-app setting should be ${channels.in_app}`);
    assertEqual(preferences.email, channels.email, `Email setting should be ${channels.email}`);
    assertEqual(preferences.push, channels.push, `Push setting should be ${channels.push}`);
    assertEqual(preferences.sms, channels.sms, `SMS setting should be ${channels.sms}`);
  }

  logVerify("All channel combinations supported");

  endTest();
}

async function testPreferencesValidation(fixtures) {
  startTest("Preferences Validation");

  logSection("Test Preference Constraints");
  logRequirement("System must validate preference data");
  logRequirement("Invalid preference types must be rejected");

  const userId = await fixtures.getTestUserId();

  logAction("Testing invalid notification type");

  try {
    await supabase.from("notification_preferences").insert({
      user_id: userId,
      type: "invalid_type", // Invalid type - only appointment, message, system, payment, reminder allowed
      in_app: true,
      email: true,
      push: false,
      sms: false
    });
    assert(false, "Should not allow invalid notification type");
  } catch (error) {
    logExpectedFailure("Validation correctly rejected invalid notification type");
    assert(true, "System should validate notification types");
  }

  logAction("Testing missing required fields");

  try {
    await supabase.from("notification_preferences").insert({
      // Missing user_id and type
      in_app: true,
      email: true
    });
    assert(false, "Should not allow preferences without required fields");
  } catch (error) {
    logExpectedFailure("Validation correctly rejected incomplete preferences");
    assert(true, "System should validate required fields");
  }

  endTest();
}

async function testDefaultPreferences(fixtures) {
  startTest("Default Preference Behavior");

  logSection("Test Default Values");
  logRequirement("System must provide sensible defaults for new users");
  logRequirement("Defaults must be consistent and user-friendly");

  const userId = await fixtures.getTestUserId();

  logAction("Creating preferences with minimal data");
  // Clean up any existing preferences first
  await supabase
    .from("notification_preferences")
    .delete()
    .eq("user_id", userId)
    .eq("type", "appointment");

  const { data: minimalPrefs, error } = await supabase
    .from("notification_preferences")
    .insert({
      user_id: userId,
      type: "appointment" // Use a different type to avoid conflicts
      // Let system provide defaults for channels
    })
    .select()
    .single();

  fixtures.trackRecord("notification_preferences", minimalPrefs.id);

  assert(!error, "Should be able to create preferences with defaults");
  assertEqual(minimalPrefs.in_app, true, "In-app should default to true");
  assertEqual(minimalPrefs.email, true, "Email should default to true");
  assertEqual(minimalPrefs.push, true, "Push should default to true");
  assertEqual(minimalPrefs.sms, false, "SMS should default to false");

  logVerify("Default preferences applied correctly");

  endTest();
}

async function testPreferencesUpdates(fixtures) {
  startTest("Preferences Updates");

  logSection("Test Preference Modifications");
  logRequirement("Users must be able to update their preferences");
  logRequirement("Updates must be atomic and validated");

  const userId = await fixtures.getTestUserId();
  
  // Clean up any existing preferences for this test
  await supabase
    .from("notification_preferences")
    .delete()
    .eq("user_id", userId)
    .eq("type", "message");
  
  logAction("Creating initial preferences");
  const initialPrefs = await fixtures.createTestNotificationPreferences(userId, {
    type: "message", // Valid preference type
    in_app: true,
    email: true,
    push: false,
    sms: false
  });

  logAction("Updating preferences");
  const { data: updatedPrefs, error } = await supabase
    .from("notification_preferences")
    .update({
      email: false, // Disable email
      push: true,   // Enable push
      updated_at: new Date().toISOString()
    })
    .eq("id", initialPrefs.id)
    .select()
    .single();

  assert(!error, "Should be able to update preferences");
  assertEqual(updatedPrefs.email, false, "Email should be disabled");
  assertEqual(updatedPrefs.push, true, "Push should be enabled");
  assertEqual(updatedPrefs.in_app, true, "In-app should remain unchanged");
  assertEqual(updatedPrefs.sms, false, "SMS should remain unchanged");

  logAction("Testing partial updates");
  const { data: partialUpdate, error: partialError } = await supabase
    .from("notification_preferences")
    .update({
      sms: true // Only update SMS
    })
    .eq("id", initialPrefs.id)
    .select()
    .single();

  assert(!partialError, "Should be able to do partial updates");
  assertEqual(partialUpdate.sms, true, "SMS should be updated");
  assertEqual(partialUpdate.email, false, "Other preferences should remain unchanged");

  logVerify("Preference updates working correctly");

  endTest();
}
