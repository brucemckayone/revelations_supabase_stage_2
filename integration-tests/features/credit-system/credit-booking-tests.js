import {
  log,
  startTest,
  endTest,
  assert,
  assertEqual,
  assertNotNull,
  assertGreaterThan,
  callFunction,
  generateTestData,
  getTestUsers,
  delay,
  isValidUUID,
} from "../../utils/test-helpers.js";
import { supabase, TEST_CONFIG } from "../../config/database.js";
import cleanupTestData from "../../utils/cleanup.js";

// Test data storage for cleanup
let testData = {
  events: [],
  packages: [],
  purchases: [],
  users: [],
};

export async function runCreditBookingTests() {
  log("🧪 Starting Credit Booking System Tests", "info");

  try {
    // Clean up any existing test data
    await cleanupTestData();

    // Run test scenarios
    await testCanBookEventWithCredits();
    await testBookEventWithCredits();
    await testCreditDeductionFIFO();
    await testInsufficientCredits();
    await testMultipleEventBookings();
    await testCreditUsageTracking();

    log("✅ All credit booking tests completed", "success");
  } catch (error) {
    log(`❌ Credit booking tests failed: ${error.message}`, "error");
    throw error;
  } finally {
    // Clean up test data
    await cleanupTestData();
  }
}

async function testCanBookEventWithCredits() {
  startTest("can_book_event_with_credits() function validation");

  // Setup test data
  const testDataGen = generateTestData();
  const users = await getTestUsers(1);

  if (users.length === 0) {
    throw new Error("No test users available");
  }

  const testUser = users[0];

  // Create test event
  const { data: event, error: eventError } = await supabase
    .from("events")
    .insert({
      ...testDataGen.event,
      creator_id: TEST_CONFIG.CREATOR_USER_ID,
    })
    .select()
    .single();

  assert(!eventError, "Event created successfully");
  assertNotNull(event?.id, "Event has valid ID");
  testData.events.push(event.id);

  // Create event date
  const { data: eventDate, error: dateError } = await supabase
    .from("event_dates")
    .insert({
      event_id: event.id,
      date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(), // Next week
      start_time: "10:00:00",
      end_time: "11:00:00",
      max_capacity: 10,
    })
    .select()
    .single();

  assert(!dateError, "Event date created successfully");

  // Create ticket type
  const { data: ticket, error: ticketError } = await supabase
    .from("tickets")
    .insert({
      event_id: event.id,
      name: "Standard Ticket",
      price: 2500, // $25.00
      capacity: 10,
    })
    .select()
    .single();

  assert(!ticketError, "Ticket created successfully");

  // Create universal package
  const { data: package_, error: packageError } = await supabase
    .from("universal_packages")
    .insert({
      ...testDataGen.package,
      creator_id: TEST_CONFIG.CREATOR_USER_ID,
      event_access_config: {
        max_events_per_month: 5,
        eligible_event_types: ["workshop"],
      },
    })
    .select()
    .single();

  assert(!packageError, "Universal package created successfully");
  testData.packages.push(package_.id);

  // Create package purchase with credits
  const { data: purchase, error: purchaseError } = await supabase
    .from("universal_package_purchases")
    .insert({
      universal_package_id: package_.id,
      user_id: testUser.id,
      payment_intent_id: `pi_test_${Date.now()}`,
      amount: package_.price,
      currency: "usd",
      status: "completed",
      credits_remaining: package_.credits,
      expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(), // 30 days
    })
    .select()
    .single();

  assert(!purchaseError, "Package purchase created successfully");
  testData.purchases.push(purchase.id);

  // Test: Can book with sufficient credits
  const { data: canBook, error: canBookError } = await callFunction(
    "can_book_event_with_credits",
    {
      p_user_id: testUser.id,
      p_event_id: event.id,
      p_ticket_id: ticket.id,
      p_quantity: 1,
    }
  );

  assert(!canBookError, "can_book_event_with_credits executed without error");
  assert(canBook === true, "User can book event with available credits");

  // Test: Cannot book with excessive quantity
  const { data: cannotBook, error: cannotBookError } = await callFunction(
    "can_book_event_with_credits",
    {
      p_user_id: testUser.id,
      p_event_id: event.id,
      p_ticket_id: ticket.id,
      p_quantity: 20, // More than available credits
    }
  );

  assert(
    !cannotBookError,
    "can_book_event_with_credits executed without error for excessive quantity"
  );
  assert(
    cannotBook === false,
    "User cannot book event with insufficient credits"
  );

  endTest();
}

async function testBookEventWithCredits() {
  startTest("book_event_with_credits() function validation");

  // Setup test data
  const testDataGen = generateTestData();
  const users = await getTestUsers(1);
  const testUser = users[0];

  // Create test event
  const { data: event, error: eventError } = await supabase
    .from("events")
    .insert({
      ...testDataGen.event,
      title: `${testDataGen.event.title}_booking`,
      creator_id: TEST_CONFIG.CREATOR_USER_ID,
    })
    .select()
    .single();

  assert(!eventError, "Event created successfully");
  testData.events.push(event.id);

  // Create event date
  const { data: eventDate, error: dateError } = await supabase
    .from("event_dates")
    .insert({
      event_id: event.id,
      date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
      start_time: "14:00:00",
      end_time: "15:00:00",
      max_capacity: 5,
    })
    .select()
    .single();

  assert(!dateError, "Event date created successfully");

  // Create ticket type
  const { data: ticket, error: ticketError } = await supabase
    .from("tickets")
    .insert({
      event_id: event.id,
      name: "Premium Ticket",
      price: 3000, // $30.00
      capacity: 5,
    })
    .select()
    .single();

  assert(!ticketError, "Ticket created successfully");

  // Create universal package
  const { data: package_, error: packageError } = await supabase
    .from("universal_packages")
    .insert({
      ...testDataGen.package,
      name: `${testDataGen.package.name}_booking`,
      creator_id: TEST_CONFIG.CREATOR_USER_ID,
    })
    .select()
    .single();

  assert(!packageError, "Universal package created successfully");
  testData.packages.push(package_.id);

  // Create package purchase
  const { data: purchase, error: purchaseError } = await supabase
    .from("universal_package_purchases")
    .insert({
      universal_package_id: package_.id,
      user_id: testUser.id,
      payment_intent_id: `pi_test_book_${Date.now()}`,
      amount: package_.price,
      currency: "usd",
      status: "completed",
      credits_remaining: package_.credits,
      expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
    })
    .select()
    .single();

  assert(!purchaseError, "Package purchase created successfully");
  testData.purchases.push(purchase.id);

  // Get initial credits
  const initialCredits = purchase.credits_remaining;

  // Book event with credits
  const { data: booking, error: bookingError } = await callFunction(
    "book_event_with_credits",
    {
      p_package_purchase_id: purchase.id,
      p_event_id: event.id,
      p_date_id: eventDate.id,
      p_ticket_id: ticket.id,
      p_quantity: 2,
    }
  );

  assert(!bookingError, "book_event_with_credits executed without error");
  assertNotNull(booking, "Booking returned valid data");
  assert(isValidUUID(booking), "Booking ID is valid UUID");

  // Verify booking was created
  const { data: eventBooking, error: bookingFetchError } = await supabase
    .from("event_bookings")
    .select("*")
    .eq("id", booking)
    .single();

  assert(!bookingFetchError, "Event booking fetched successfully");
  assertNotNull(eventBooking, "Event booking exists in database");
  assertEqual(eventBooking.event_id, event.id, "Booking has correct event ID");
  assertEqual(eventBooking.user_id, testUser.id, "Booking has correct user ID");
  assertEqual(eventBooking.quantity, 2, "Booking has correct quantity");

  // Verify credits were deducted
  const { data: updatedPurchase, error: purchaseFetchError } = await supabase
    .from("universal_package_purchases")
    .select("credits_remaining")
    .eq("id", purchase.id)
    .single();

  assert(!purchaseFetchError, "Updated purchase fetched successfully");
  assertEqual(
    updatedPurchase.credits_remaining,
    initialCredits - 2,
    "Credits were deducted correctly"
  );

  // Verify usage tracking
  const { data: usage, error: usageError } = await supabase
    .from("universal_package_event_usage")
    .select("*")
    .eq("universal_package_purchase_id", purchase.id)
    .eq("event_booking_id", booking);

  assert(!usageError, "Usage records fetched successfully");
  assertEqual(usage.length, 1, "One usage record created");
  assertEqual(
    usage[0].credits_used,
    2,
    "Usage record has correct credits used"
  );

  endTest();
}

async function testCreditDeductionFIFO() {
  startTest("Credit deduction follows FIFO (First In, First Out) logic");

  const testDataGen = generateTestData();
  const users = await getTestUsers(1);
  const testUser = users[0];

  // Create test event
  const { data: event, error: eventError } = await supabase
    .from("events")
    .insert({
      ...testDataGen.event,
      title: `${testDataGen.event.title}_fifo`,
      creator_id: TEST_CONFIG.CREATOR_USER_ID,
    })
    .select()
    .single();

  assert(!eventError, "Event created successfully");
  testData.events.push(event.id);

  // Create event date and ticket
  const { data: eventDate } = await supabase
    .from("event_dates")
    .insert({
      event_id: event.id,
      date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
      start_time: "16:00:00",
      end_time: "17:00:00",
      max_capacity: 10,
    })
    .select()
    .single();

  const { data: ticket } = await supabase
    .from("tickets")
    .insert({
      event_id: event.id,
      name: "FIFO Test Ticket",
      price: 2000,
      capacity: 10,
    })
    .select()
    .single();

  // Create universal package
  const { data: package_ } = await supabase
    .from("universal_packages")
    .insert({
      ...testDataGen.package,
      name: `${testDataGen.package.name}_fifo`,
      credits: 5,
      creator_id: TEST_CONFIG.CREATOR_USER_ID,
    })
    .select()
    .single();

  testData.packages.push(package_.id);

  // Create two purchases at different times (older first)
  const { data: oldPurchase } = await supabase
    .from("universal_package_purchases")
    .insert({
      universal_package_id: package_.id,
      user_id: testUser.id,
      payment_intent_id: `pi_test_old_${Date.now()}`,
      amount: package_.price,
      currency: "usd",
      status: "completed",
      credits_remaining: 3,
      purchased_at: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(), // Yesterday
      expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
    })
    .select()
    .single();

  testData.purchases.push(oldPurchase.id);

  await delay(100); // Small delay to ensure different timestamps

  const { data: newPurchase } = await supabase
    .from("universal_package_purchases")
    .insert({
      universal_package_id: package_.id,
      user_id: testUser.id,
      payment_intent_id: `pi_test_new_${Date.now()}`,
      amount: package_.price,
      currency: "usd",
      status: "completed",
      credits_remaining: 5,
      purchased_at: new Date().toISOString(), // Now
      expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
    })
    .select()
    .single();

  testData.purchases.push(newPurchase.id);

  // Book 4 credits (should use 3 from old purchase + 1 from new)
  const { data: booking } = await callFunction("book_event_with_credits", {
    p_package_purchase_id: oldPurchase.id, // Start with old purchase
    p_event_id: event.id,
    p_date_id: eventDate.id,
    p_ticket_id: ticket.id,
    p_quantity: 4,
  });

  assert(booking, "Booking completed successfully");

  // Verify old purchase is depleted
  const { data: updatedOldPurchase } = await supabase
    .from("universal_package_purchases")
    .select("credits_remaining")
    .eq("id", oldPurchase.id)
    .single();

  assertEqual(
    updatedOldPurchase.credits_remaining,
    0,
    "Old purchase depleted first"
  );

  // Verify new purchase has 4 credits remaining (5 - 1 used)
  const { data: updatedNewPurchase } = await supabase
    .from("universal_package_purchases")
    .select("credits_remaining")
    .eq("id", newPurchase.id)
    .single();

  assertEqual(
    updatedNewPurchase.credits_remaining,
    4,
    "New purchase has correct remaining credits"
  );

  endTest();
}

async function testInsufficientCredits() {
  startTest("Insufficient credits error handling");

  const testDataGen = generateTestData();
  const users = await getTestUsers(1);
  const testUser = users[0];

  // Create test event
  const { data: event } = await supabase
    .from("events")
    .insert({
      ...testDataGen.event,
      title: `${testDataGen.event.title}_insufficient`,
      creator_id: TEST_CONFIG.CREATOR_USER_ID,
    })
    .select()
    .single();

  testData.events.push(event.id);

  const { data: eventDate } = await supabase
    .from("event_dates")
    .insert({
      event_id: event.id,
      date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
      start_time: "18:00:00",
      end_time: "19:00:00",
      max_capacity: 10,
    })
    .select()
    .single();

  const { data: ticket } = await supabase
    .from("tickets")
    .insert({
      event_id: event.id,
      name: "Insufficient Test Ticket",
      price: 2000,
      capacity: 10,
    })
    .select()
    .single();

  // Create package with limited credits
  const { data: package_ } = await supabase
    .from("universal_packages")
    .insert({
      ...testDataGen.package,
      name: `${testDataGen.package.name}_insufficient`,
      credits: 2, // Only 2 credits
      creator_id: TEST_CONFIG.CREATOR_USER_ID,
    })
    .select()
    .single();

  testData.packages.push(package_.id);

  const { data: purchase } = await supabase
    .from("universal_package_purchases")
    .insert({
      universal_package_id: package_.id,
      user_id: testUser.id,
      payment_intent_id: `pi_test_insufficient_${Date.now()}`,
      amount: package_.price,
      currency: "usd",
      status: "completed",
      credits_remaining: 2,
      expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
    })
    .select()
    .single();

  testData.purchases.push(purchase.id);

  // Try to book more credits than available
  const { data: booking, error: bookingError } = await callFunction(
    "book_event_with_credits",
    {
      p_package_purchase_id: purchase.id,
      p_event_id: event.id,
      p_date_id: eventDate.id,
      p_ticket_id: ticket.id,
      p_quantity: 5, // More than 2 available
    }
  );

  assert(
    bookingError !== null,
    "Booking with insufficient credits should fail"
  );
  assert(booking === null, "No booking should be created");

  // Verify credits unchanged
  const { data: unchangedPurchase } = await supabase
    .from("universal_package_purchases")
    .select("credits_remaining")
    .eq("id", purchase.id)
    .single();

  assertEqual(
    unchangedPurchase.credits_remaining,
    2,
    "Credits remain unchanged after failed booking"
  );

  endTest();
}

async function testMultipleEventBookings() {
  startTest("Multiple event bookings with credit management");

  const testDataGen = generateTestData();
  const users = await getTestUsers(1);
  const testUser = users[0];

  // Create multiple test events
  const events = [];
  for (let i = 0; i < 3; i++) {
    const { data: event } = await supabase
      .from("events")
      .insert({
        ...testDataGen.event,
        title: `${testDataGen.event.title}_multi_${i}`,
        creator_id: TEST_CONFIG.CREATOR_USER_ID,
      })
      .select()
      .single();

    events.push(event);
    testData.events.push(event.id);
  }

  // Create universal package with enough credits
  const { data: package_ } = await supabase
    .from("universal_packages")
    .insert({
      ...testDataGen.package,
      name: `${testDataGen.package.name}_multi`,
      credits: 10,
      creator_id: TEST_CONFIG.CREATOR_USER_ID,
    })
    .select()
    .single();

  testData.packages.push(package_.id);

  const { data: purchase } = await supabase
    .from("universal_package_purchases")
    .insert({
      universal_package_id: package_.id,
      user_id: testUser.id,
      payment_intent_id: `pi_test_multi_${Date.now()}`,
      amount: package_.price,
      currency: "usd",
      status: "completed",
      credits_remaining: 10,
      expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
    })
    .select()
    .single();

  testData.purchases.push(purchase.id);

  // Book multiple events
  let totalCreditsUsed = 0;
  const bookings = [];

  for (let i = 0; i < events.length; i++) {
    const event = events[i];

    // Create event date and ticket for each event
    const { data: eventDate } = await supabase
      .from("event_dates")
      .insert({
        event_id: event.id,
        date: new Date(
          Date.now() + (i + 1) * 7 * 24 * 60 * 60 * 1000
        ).toISOString(),
        start_time: "10:00:00",
        end_time: "11:00:00",
        max_capacity: 5,
      })
      .select()
      .single();

    const { data: ticket } = await supabase
      .from("tickets")
      .insert({
        event_id: event.id,
        name: `Multi Test Ticket ${i}`,
        price: 2000 + i * 500,
        capacity: 5,
      })
      .select()
      .single();

    const creditsToUse = i + 1; // 1, 2, 3 credits respectively

    const { data: booking } = await callFunction("book_event_with_credits", {
      p_package_purchase_id: purchase.id,
      p_event_id: event.id,
      p_date_id: eventDate.id,
      p_ticket_id: ticket.id,
      p_quantity: creditsToUse,
    });

    assert(booking, `Booking ${i + 1} completed successfully`);
    bookings.push(booking);
    totalCreditsUsed += creditsToUse;
  }

  // Verify total credits used (1 + 2 + 3 = 6)
  const { data: finalPurchase } = await supabase
    .from("universal_package_purchases")
    .select("credits_remaining")
    .eq("id", purchase.id)
    .single();

  assertEqual(
    finalPurchase.credits_remaining,
    10 - totalCreditsUsed,
    "Total credits deducted correctly"
  );

  // Verify all bookings exist
  const { data: allBookings } = await supabase
    .from("event_bookings")
    .select("*")
    .in("id", bookings);

  assertEqual(allBookings.length, 3, "All three bookings created");

  endTest();
}

async function testCreditUsageTracking() {
  startTest("Credit usage tracking and audit trail");

  const testDataGen = generateTestData();
  const users = await getTestUsers(1);
  const testUser = users[0];

  // Create test event
  const { data: event } = await supabase
    .from("events")
    .insert({
      ...testDataGen.event,
      title: `${testDataGen.event.title}_tracking`,
      creator_id: TEST_CONFIG.CREATOR_USER_ID,
    })
    .select()
    .single();

  testData.events.push(event.id);

  const { data: eventDate } = await supabase
    .from("event_dates")
    .insert({
      event_id: event.id,
      date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
      start_time: "20:00:00",
      end_time: "21:00:00",
      max_capacity: 5,
    })
    .select()
    .single();

  const { data: ticket } = await supabase
    .from("tickets")
    .insert({
      event_id: event.id,
      name: "Tracking Test Ticket",
      price: 2500,
      capacity: 5,
    })
    .select()
    .single();

  // Create package and purchase
  const { data: package_ } = await supabase
    .from("universal_packages")
    .insert({
      ...testDataGen.package,
      name: `${testDataGen.package.name}_tracking`,
      creator_id: TEST_CONFIG.CREATOR_USER_ID,
    })
    .select()
    .single();

  testData.packages.push(package_.id);

  const { data: purchase } = await supabase
    .from("universal_package_purchases")
    .insert({
      universal_package_id: package_.id,
      user_id: testUser.id,
      payment_intent_id: `pi_test_tracking_${Date.now()}`,
      amount: package_.price,
      currency: "usd",
      status: "completed",
      credits_remaining: package_.credits,
      expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
    })
    .select()
    .single();

  testData.purchases.push(purchase.id);

  // Book event
  const { data: booking } = await callFunction("book_event_with_credits", {
    p_package_purchase_id: purchase.id,
    p_event_id: event.id,
    p_date_id: eventDate.id,
    p_ticket_id: ticket.id,
    p_quantity: 3,
  });

  assert(booking, "Booking completed successfully");

  // Verify usage tracking record
  const { data: usageRecords } = await supabase
    .from("universal_package_event_usage")
    .select(
      `
      *,
      universal_package_purchases!inner(user_id),
      event_bookings!inner(event_id, quantity)
    `
    )
    .eq("universal_package_purchase_id", purchase.id)
    .eq("event_booking_id", booking);

  assert(usageRecords.length === 1, "One usage record created");

  const usage = usageRecords[0];
  assertEqual(usage.credits_used, 3, "Usage record has correct credits used");
  assertEqual(
    usage.universal_package_purchases.user_id,
    testUser.id,
    "Usage linked to correct user"
  );
  assertEqual(
    usage.event_bookings.event_id,
    event.id,
    "Usage linked to correct event"
  );
  assertEqual(
    usage.event_bookings.quantity,
    3,
    "Usage quantity matches booking"
  );
  assertNotNull(usage.used_at, "Usage timestamp recorded");

  // Test total usage aggregation
  const { data: totalUsage } = await supabase
    .from("universal_package_event_usage")
    .select("credits_used")
    .eq("universal_package_purchase_id", purchase.id);

  const totalCreditsUsed = totalUsage.reduce(
    (sum, record) => sum + record.credits_used,
    0
  );
  assertEqual(totalCreditsUsed, 3, "Total usage aggregation correct");

  endTest();
}

export default runCreditBookingTests;
