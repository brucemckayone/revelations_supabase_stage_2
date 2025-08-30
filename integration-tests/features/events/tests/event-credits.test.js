import {
  assert,
  assertEqual,
  assertNotNull,
  assertGreaterThan,
  callFunction,
} from "../../../shared/utilities/test-utils.js";
import { EventsFixtures } from "../fixtures.js";
import { getTestUsers } from "../../../config/test-users.js";
import { supabase } from "../../../config/database.js";
import { TestUserManager } from "../../../shared/utilities/test-user-manager.js";

const TEST_AUTH_EMAIL =
  process.env.TEST_USER_EMAIL || "brucemckayone@gmail.com";
const TEST_AUTH_PASSWORD = process.env.TEST_USER_PASSWORD || "password123";
const userManager = new TestUserManager();

async function callBookWithCredits(params) {
  // Use the test version that bypasses authentication and accepts user_id directly
  const userId = userManager.getUserId();
  return await supabase.rpc("test_book_event_with_credits", {
    p_user_id: userId,
    ...params,
  });
}

export async function runEventCreditsTests() {
  const fixtures = new EventsFixtures();

  try {
    // Test basic event booking with credits
    await testBasicCreditBooking(fixtures);

    // Test credit validation and insufficient credits
    await testCreditValidation(fixtures);

    // Test multiple event bookings with credits
    await testMultipleCreditBookings(fixtures);

    // Test credit usage tracking
    await testCreditUsageTracking(fixtures);

    // Test expired package handling
    await testExpiredPackageHandling(fixtures);

    // Test credit booking with different ticket prices
    await testCreditBookingWithDifferentPrices(fixtures);

    // Test package credit consumption and remaining credits
    await testCreditConsumption(fixtures);
  } catch (error) {
    console.error(`Event credits test failed: ${error.message}`);
    console.log("Cleanup status at error:", fixtures.getCleanupStatus());
    throw error;
  } finally {
    // Enhanced cleanup with status reporting
    const statusBefore = fixtures.getCleanupStatus();
    if (statusBefore.totalRecords > 0) {
      console.log(
        `Starting cleanup of ${statusBefore.totalRecords} tracked records...`
      );
    }

    const cleanedCount = await fixtures.cleanup();

    if (cleanedCount > 0) {
      console.log(`Cleanup completed: ${cleanedCount} records removed`);
    }
  }
}

async function testBasicCreditBooking(fixtures) {
  console.log("Testing basic event booking with universal package credits...");

  // Create an event package with credits
  const package_ = await fixtures.createTestEventPackage({
    total_event_credits: 5,
    price: 10000, // $100.00
  });

  // Get the test user that we'll use consistently
  const testUserId = userManager.getUserId();

  // Create a package purchase with credits for the same user
  const { packagePurchase, user } = await fixtures.createTestPackagePurchase(
    package_.id,
    {
      event_credits_remaining: 5,
      user_id: testUserId, // Ensure it's created for the right user
    }
  );

  // Create an event to book
  const event = await fixtures.createTestEvent();

  // Test booking the event with credits using authenticated user
  const { data, error } = await callBookWithCredits({
    p_package_purchase_id: packagePurchase.id,
    p_event_id: event.event.id,
    p_date_id: event.dates[0].id,
    p_ticket_id: event.tickets[0].id,
    p_quantity: 1,
  });

  if (error) {
    console.log("Credit booking error details:", error);
  }

  assert(!error, "book_event_with_credits should execute without error");
  assertNotNull(data, "Function should return booking result");

  // Verify the booking result
  assertEqual(data.success, true, "Booking should be successful");
  assertNotNull(data.booking_id, "Booking ID should be returned");
  assertNotNull(data.purchase_id, "Purchase ID should be returned");
  assertEqual(data.credits_used, 1, "Should use 1 credit per booking");
  assertEqual(data.credits_remaining, 4, "Should have 4 credits remaining");
  assertGreaterThan(
    data.total_saved,
    0,
    "Should show savings from using credits"
  );

  // Verify the purchase record was created and modified correctly
  const { data: purchase } = await supabase
    .from("purchases")
    .select("*")
    .eq("id", data.purchase_id)
    .single();

  assertEqual(
    purchase.amount,
    0,
    "Purchase amount should be 0 when paid with credits"
  );
  assertEqual(
    purchase.payment_status,
    "completed",
    "Payment should be completed"
  );
  assertNotNull(purchase.metadata, "Purchase should have metadata");
  assertEqual(
    purchase.metadata.paid_with_credits,
    true,
    "Should be marked as paid with credits"
  );
  assertEqual(
    purchase.metadata.package_purchase_id,
    packagePurchase.id,
    "Should reference package purchase"
  );
  assertEqual(purchase.metadata.credits_used, 1, "Should record credits used");

  // Verify the event booking was created
  const { data: booking } = await supabase
    .from("event_bookings")
    .select("*")
    .eq("id", data.booking_id)
    .single();

  assertEqual(
    booking.purchase_id,
    data.purchase_id,
    "Booking should link to purchase"
  );
  assertEqual(booking.event_id, event.event.id, "Booking should link to event");
  assertEqual(booking.status, "confirmed", "Booking should be confirmed");

  // Verify credits were deducted from the package
  const { data: updatedPackagePurchase } = await supabase
    .from("universal_package_purchases")
    .select("event_credits_remaining")
    .eq("id", packagePurchase.id)
    .single();

  assertEqual(
    updatedPackagePurchase.event_credits_remaining,
    4,
    "Package should have 4 credits remaining"
  );

  // Verify usage tracking was created
  const { data: usageRecords } = await supabase
    .from("universal_package_event_usage")
    .select("*")
    .eq("package_purchase_id", packagePurchase.id);

  assertGreaterThan(
    usageRecords.length,
    0,
    "Should have usage tracking record"
  );
  assertEqual(
    usageRecords[0].event_booking_id,
    data.booking_id,
    "Usage should link to booking"
  );
  assertEqual(
    usageRecords[0].credits_used,
    1,
    "Usage should record 1 credit used"
  );

  // Track for cleanup with proper dependencies
  fixtures.trackRecord("purchases", data.purchase_id);
  fixtures.trackRecord("event_bookings", data.booking_id, {
    parentTable: "purchases",
    parentId: data.purchase_id,
  });
}

async function testCreditValidation(fixtures) {
  console.log("Testing credit validation and insufficient credits...");

  // Create a package with limited credits
  const package_ = await fixtures.createTestEventPackage({
    total_event_credits: 2,
  });

  // Get the same test user that will be used in the function call
  const testUserId = userManager.getUserId();

  const { packagePurchase } = await fixtures.createTestPackagePurchase(
    package_.id,
    {
      event_credits_remaining: 1, // Only 1 credit remaining
      user_id: testUserId, // Ensure it's created for the right user
    }
  );

  const event = await fixtures.createTestEvent();

  // Test booking with sufficient credits (should succeed)
  const { data: successData, error: successError } = await callBookWithCredits({
    p_package_purchase_id: packagePurchase.id,
    p_event_id: event.event.id,
    p_date_id: event.dates[0].id,
    p_ticket_id: event.tickets[0].id,
    p_quantity: 1,
  });

  assert(!successError, "Booking with sufficient credits should succeed");
  assertEqual(successData.credits_used, 1, "Should use 1 credit");

  // Test booking with insufficient credits (should fail)
  const { data: failData, error: failError } = await callBookWithCredits({
    p_package_purchase_id: packagePurchase.id,
    p_event_id: event.event.id,
    p_date_id: event.dates[0].id,
    p_ticket_id: event.tickets[0].id,
    p_quantity: 1, // Requires 1 credit but only 0 remaining
  });

  assert(failError !== null, "Booking with insufficient credits should fail");
  assert(
    failError.message.includes("Insufficient credits"),
    "Error should mention insufficient credits"
  );

  // Test booking with multiple quantity exceeding credits
  const { packagePurchase: newPackagePurchase } =
    await fixtures.createTestPackagePurchase(package_.id, {
      event_credits_remaining: 2,
      user_id: testUserId,
    });

  const { data: multiFailData, error: multiFailError } =
    await callBookWithCredits({
      p_package_purchase_id: newPackagePurchase.id,
      p_event_id: event.event.id,
      p_date_id: event.dates[0].id,
      p_ticket_id: event.tickets[0].id,
      p_quantity: 3, // Requires 3 credits but only 2 available
    });

  assert(
    multiFailError !== null,
    "Booking quantity exceeding credits should fail"
  );

  // Track for cleanup
  if (successData) {
    fixtures.trackRecord("purchases", successData.purchase_id);
    fixtures.trackRecord("event_bookings", successData.booking_id);
  }
}

async function testMultipleCreditBookings(fixtures) {
  console.log("Testing multiple event bookings with credits...");

  // Create a package with multiple credits
  const package_ = await fixtures.createTestEventPackage({
    total_event_credits: 5,
  });

  // Get the same test user that will be used in the function call
  const testUserId = userManager.getUserId();

  const { packagePurchase } = await fixtures.createTestPackagePurchase(
    package_.id,
    {
      event_credits_remaining: 5,
      user_id: testUserId,
    }
  );

  // Create multiple events
  const event1 = await fixtures.createTestEvent();
  const event2 = await fixtures.createTestEvent();

  // Book first event
  const { data: booking1, error: error1 } = await callBookWithCredits({
    p_package_purchase_id: packagePurchase.id,
    p_event_id: event1.event.id,
    p_date_id: event1.dates[0].id,
    p_ticket_id: event1.tickets[0].id,
    p_quantity: 1,
  });

  assert(!error1, "First booking should succeed");
  assertEqual(
    booking1.credits_remaining,
    4,
    "Should have 4 credits remaining after first booking"
  );

  // Book second event with multiple quantity
  const { data: booking2, error: error2 } = await callBookWithCredits({
    p_package_purchase_id: packagePurchase.id,
    p_event_id: event2.event.id,
    p_date_id: event2.dates[0].id,
    p_ticket_id: event2.tickets[0].id,
    p_quantity: 2,
  });

  assert(!error2, "Second booking should succeed");
  assertEqual(booking2.credits_used, 2, "Should use 2 credits for quantity 2");
  assertEqual(
    booking2.credits_remaining,
    2,
    "Should have 2 credits remaining after second booking"
  );

  // Verify final package state
  const { data: finalPackageState } = await supabase
    .from("universal_package_purchases")
    .select("event_credits_remaining")
    .eq("id", packagePurchase.id)
    .single();

  assertEqual(
    finalPackageState.event_credits_remaining,
    2,
    "Package should have 2 credits remaining"
  );

  // Verify usage tracking records
  const { data: usageRecords } = await supabase
    .from("universal_package_event_usage")
    .select("*")
    .eq("package_purchase_id", packagePurchase.id)
    .order("created_at");

  assertEqual(usageRecords.length, 2, "Should have 2 usage records");
  assertEqual(
    usageRecords[0].credits_used,
    1,
    "First usage should be 1 credit"
  );
  assertEqual(
    usageRecords[1].credits_used,
    2,
    "Second usage should be 2 credits"
  );

  // Track for cleanup
  fixtures.trackRecord("purchases", booking1.purchase_id);
  fixtures.trackRecord("event_bookings", booking1.booking_id);
  fixtures.trackRecord("purchases", booking2.purchase_id);
  fixtures.trackRecord("event_bookings", booking2.booking_id);
}

async function testCreditUsageTracking(fixtures) {
  console.log("Testing credit usage tracking...");

  const package_ = await fixtures.createTestEventPackage({
    total_event_credits: 3,
  });

  // Get the same test user that will be used in the function call
  const testUserId = userManager.getUserId();

  const { packagePurchase } = await fixtures.createTestPackagePurchase(
    package_.id,
    {
      event_credits_remaining: 3,
      user_id: testUserId,
    }
  );

  const event = await fixtures.createTestEvent();

  // Book event with credits
  const { data, error } = await callBookWithCredits({
    p_package_purchase_id: packagePurchase.id,
    p_event_id: event.event.id,
    p_date_id: event.dates[0].id,
    p_ticket_id: event.tickets[0].id,
    p_quantity: 1,
  });

  assert(!error, "Credit booking should succeed");

  // Verify detailed usage tracking
  const { data: usageRecord } = await supabase
    .from("universal_package_event_usage")
    .select("*")
    .eq("package_purchase_id", packagePurchase.id)
    .single();

  assertNotNull(usageRecord, "Usage record should exist");
  assertEqual(
    usageRecord.event_booking_id,
    data.booking_id,
    "Should link to booking"
  );
  assertEqual(usageRecord.event_id, event.event.id, "Should link to event");
  assertEqual(
    usageRecord.ticket_id,
    event.tickets[0].id,
    "Should link to ticket"
  );
  assertEqual(
    usageRecord.credits_used,
    1,
    "Should record correct credits used"
  );
  assertEqual(
    usageRecord.original_ticket_price,
    event.tickets[0].price,
    "Should record original ticket price"
  );
  assertEqual(usageRecord.ticket_quantity, 1, "Should record ticket quantity");
  assertNotNull(usageRecord.usage_context, "Should have usage context");
  assertEqual(
    usageRecord.usage_context.booking_method,
    "test_universal_credits",
    "Should record booking method (test version)"
  );

  // Track for cleanup with proper dependencies
  fixtures.trackRecord("purchases", data.purchase_id);
  fixtures.trackRecord("event_bookings", data.booking_id, {
    parentTable: "purchases",
    parentId: data.purchase_id,
  });
}

async function testExpiredPackageHandling(fixtures) {
  console.log("Testing expired package handling...");

  const package_ = await fixtures.createTestEventPackage({
    total_event_credits: 3,
    duration_weeks: 4, // 1 month = 4 weeks
  });

  // Get the same test user that will be used in the function call
  const testUserId = userManager.getUserId();

  // Create an expired package purchase
  const { packagePurchase } = await fixtures.createTestPackagePurchase(
    package_.id,
    {
      event_credits_remaining: 3,
      expires_at: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(), // Expired yesterday
      user_id: testUserId,
    }
  );

  const event = await fixtures.createTestEvent();

  // Test booking with expired package
  const { data, error } = await callBookWithCredits({
    p_package_purchase_id: packagePurchase.id,
    p_event_id: event.event.id,
    p_date_id: event.dates[0].id,
    p_ticket_id: event.tickets[0].id,
    p_quantity: 1,
  });

  assert(error !== null, "Booking with expired package should fail");
  assert(
    error.message.includes("expired"),
    "Error should mention package expiration"
  );
}

async function testCreditBookingWithDifferentPrices(fixtures) {
  console.log("Testing credit booking with different ticket prices...");

  const package_ = await fixtures.createTestEventPackage({
    total_event_credits: 5,
  });

  // Get the same test user that will be used in the function call
  const testUserId = userManager.getUserId();

  const { packagePurchase } = await fixtures.createTestPackagePurchase(
    package_.id,
    {
      event_credits_remaining: 5,
      user_id: testUserId,
    }
  );

  // Create event with multiple ticket types
  const event = await fixtures.createMultiTicketEvent();

  // Test booking each ticket type (all should use 1 credit regardless of price)
  for (const ticket of event.tickets) {
    const initialCredits = await getCurrentCredits(packagePurchase.id);

    const { data, error } = await callBookWithCredits({
      p_package_purchase_id: packagePurchase.id,
      p_event_id: event.event.id,
      p_date_id: event.dates[0].id,
      p_ticket_id: ticket.id,
      p_quantity: 1,
    });

    assert(!error, `Booking ${ticket.title} should succeed`);
    assertEqual(
      data.credits_used,
      1,
      `Should use 1 credit for ${ticket.title} regardless of price`
    );
    assertEqual(
      data.original_ticket_price,
      ticket.price,
      `Should record original price for ${ticket.title}`
    );
    assertEqual(
      data.total_saved,
      ticket.price,
      `Should save full ticket price for ${ticket.title}`
    );

    const finalCredits = await getCurrentCredits(packagePurchase.id);
    assertEqual(
      finalCredits,
      initialCredits - 1,
      `Should deduct 1 credit for ${ticket.title}`
    );

    // Track for cleanup
    fixtures.trackRecord("purchases", data.purchase_id);
    fixtures.trackRecord("event_bookings", data.booking_id);
  }
}

async function testCreditConsumption(fixtures) {
  console.log("Testing package credit consumption patterns...");

  const package_ = await fixtures.createTestEventPackage({
    total_event_credits: 10,
  });

  // Get the same test user that will be used in the function call
  const testUserId = userManager.getUserId();

  const { packagePurchase } = await fixtures.createTestPackagePurchase(
    package_.id,
    {
      event_credits_remaining: 10,
      user_id: testUserId,
    }
  );

  const event = await fixtures.createTestEvent();

  // Test different consumption patterns
  const consumptionTests = [
    { quantity: 1, expectedUsed: 1 },
    { quantity: 3, expectedUsed: 3 },
    { quantity: 2, expectedUsed: 2 },
  ];

  let expectedRemaining = 10;

  for (const test of consumptionTests) {
    const { data, error } = await callBookWithCredits({
      p_package_purchase_id: packagePurchase.id,
      p_event_id: event.event.id,
      p_date_id: event.dates[0].id,
      p_ticket_id: event.tickets[0].id,
      p_quantity: test.quantity,
    });

    assert(!error, `Booking with quantity ${test.quantity} should succeed`);
    assertEqual(
      data.credits_used,
      test.expectedUsed,
      `Should use ${test.expectedUsed} credits`
    );

    expectedRemaining -= test.expectedUsed;
    assertEqual(
      data.credits_remaining,
      expectedRemaining,
      `Should have ${expectedRemaining} credits remaining`
    );

    // Track for cleanup
    fixtures.trackRecord("purchases", data.purchase_id);
    fixtures.trackRecord("event_bookings", data.booking_id);
  }

  // Verify final package state
  const finalCredits = await getCurrentCredits(packagePurchase.id);
  assertEqual(
    finalCredits,
    expectedRemaining,
    "Final credits should match expected remaining"
  );

  // Test booking with remaining credits should still work
  if (expectedRemaining > 0) {
    const { data: finalBooking, error: finalError } = await callBookWithCredits(
      {
        p_package_purchase_id: packagePurchase.id,
        p_event_id: event.event.id,
        p_date_id: event.dates[0].id,
        p_ticket_id: event.tickets[0].id,
        p_quantity: Math.min(expectedRemaining, 1), // Book up to remaining credits
      }
    );

    if (expectedRemaining >= 1) {
      assert(
        !finalError,
        "Final booking should succeed with remaining credits"
      );
      fixtures.trackRecord("purchases", finalBooking.purchase_id);
      fixtures.trackRecord("event_bookings", finalBooking.booking_id);
    }
  }
}

// Helper function to get current credits for a package purchase
async function getCurrentCredits(packagePurchaseId) {
  const { data } = await supabase
    .from("universal_package_purchases")
    .select("event_credits_remaining")
    .eq("id", packagePurchaseId)
    .single();

  return data?.event_credits_remaining || 0;
}
