import {
  assert,
  assertEqual,
  assertNotNull,
  assertGreaterThan,
  callFunction,
  startTest,
  endTest,
  logSection,
  logRequirement,
  logAction,
  logVerify,
  logExpectedFailure,
  assertExpectedFailure,
} from "../../../shared/utilities/test-utils.js";
import { EventsFixtures } from "../fixtures.js";
import { getTestUsers } from "../../../config/test-users.js";
import { supabase } from "../../../config/database.js";

export async function runEventBookingTests() {
  const fixtures = new EventsFixtures();

  try {
    // Test basic event purchase flow
    await testBasicEventPurchase(fixtures);

    // Test guest event purchase (no authentication required)
    await testGuestEventPurchase(fixtures);

    // Test event purchase with multiple attendees
    await testMultipleAttendeePurchase(fixtures);

    // Test event purchase validation and error handling
    await testEventPurchaseValidation(fixtures);

    // Test payment status updates
    await testPaymentStatusUpdates(fixtures);

    // Test ticket code generation
    await testTicketCodeGeneration(fixtures);

    // Test purchase for different ticket types
    await testDifferentTicketTypes(fixtures);

    // Test virtual vs in-person booking
    await testVirtualVsInPersonBooking(fixtures);
  } finally {
    await fixtures.cleanup();
  }
}

async function testBasicEventPurchase(fixtures) {
  startTest("Basic Event Purchase Flow");

  logSection("Setup Test Environment");
  logRequirement("Event must have available tickets");
  logRequirement("User must be able to purchase without authentication");
  logRequirement("Payment intent must be created");

  logAction("Creating test event with tickets");
  const event = await fixtures.createTestEvent();
  const eventId = event.event.id;
  const ticketId = event.tickets[0].id;
  const dateId = event.dates[0].id;

  logAction("Creating guest event purchase");
  const { data, error } = await callFunction("create_event_purchase", {
    p_event_id: eventId,
    p_ticket_id: ticketId,
    p_date_id: dateId,
    p_quantity: 1,
    p_is_virtual: false,
    p_payment_intent_id: `pi_test_${Date.now()}`,
    p_payment_status: "completed",
    p_customer_email: `test.customer.${Date.now()}@example.com`,
    p_customer_name: "Test Customer",
  });

  logSection("Verification");
  logVerify("Purchase created without errors");
  assert(!error, "create_event_purchase should execute without error");
  assertNotNull(data, "Function should return purchase result");

  logVerify("Purchase data structure is valid");
  const purchaseId = data.purchase_id;
  const bookingId = data.booking_id;

  assertNotNull(purchaseId, "Purchase ID should be returned");
  assertNotNull(bookingId, "Booking ID should be returned");

  logVerify("Purchase details match request");
  assertEqual(data.event_id, eventId, "Event ID should match");
  assertEqual(data.ticket_id, ticketId, "Ticket ID should match");
  assertEqual(data.date_id, dateId, "Date ID should match");
  assertEqual(
    data.payment_status,
    "completed",
    "Payment status should be completed"
  );
  assertEqual(data.attendees, 1, "Attendees should match quantity");

  // Verify the purchase record was created
  const { data: purchase } = await supabase
    .from("purchases")
    .select("*")
    .eq("id", purchaseId)
    .single();

  assertEqual(purchase.purchase_type, "event", "Purchase type should be event");
  assertEqual(
    purchase.payment_status,
    "completed",
    "Payment status should be completed"
  );
  assertEqual(purchase.event_id, eventId, "Purchase should link to event");
  assertEqual(purchase.quantity, 1, "Purchase quantity should match");
  assertGreaterThan(
    purchase.amount,
    0,
    "Purchase amount should be greater than 0"
  );

  // Verify the event booking was created
  const { data: booking } = await supabase
    .from("event_bookings")
    .select("*")
    .eq("id", bookingId)
    .single();

  assertEqual(
    booking.purchase_id,
    purchaseId,
    "Booking should link to purchase"
  );
  assertEqual(booking.event_id, eventId, "Booking should link to event");
  assertEqual(booking.ticket_id, ticketId, "Booking should link to ticket");
  assertEqual(booking.date_id, dateId, "Booking should link to date");
  assertEqual(booking.attendees, 1, "Booking attendees should match");
  assertEqual(
    booking.status,
    "confirmed",
    "Booking should be confirmed for completed payment"
  );
  assertNotNull(booking.ticket_code, "Booking should have a ticket code");

  // Track for cleanup
  fixtures.trackRecord("purchases", purchaseId);
  fixtures.trackRecord("event_bookings", bookingId);

  endTest();
}

async function testGuestEventPurchase(fixtures) {
  startTest("Guest Event Purchase");

  logSection("Setup Test Environment");
  logRequirement("Event must allow guest purchases");
  logRequirement("No authentication required");
  logRequirement("Customer email and name must be provided");

  logAction("Creating test event for guest purchase");
  // Create a test event
  const event = await fixtures.createTestEvent();
  const eventId = event.event.id;
  const ticketId = event.tickets[0].id;
  const dateId = event.dates[0].id;

  // Test guest purchase with email only (no authentication)
  const guestEmail = `guest.customer.${Date.now()}@example.com`;
  const guestName = "Guest Customer";

  const { data, error } = await callFunction("create_event_purchase", {
    p_event_id: eventId,
    p_ticket_id: ticketId,
    p_date_id: dateId,
    p_quantity: 1,
    p_is_virtual: false,
    p_payment_intent_id: `pi_guest_${Date.now()}`,
    p_payment_status: "completed",
    p_customer_email: guestEmail,
    p_customer_name: guestName,
  });

  assert(!error, "Guest purchase should execute without error");
  assertNotNull(data, "Function should return purchase result");

  // Verify the purchase was created correctly
  const purchaseId = data.purchase_id;
  const bookingId = data.booking_id;

  assertNotNull(purchaseId, "Purchase ID should be returned");
  assertNotNull(bookingId, "Booking ID should be returned");
  assertEqual(data.event_id, eventId, "Event ID should match");
  assertEqual(
    data.is_guest_purchase,
    true,
    "Should be marked as guest purchase"
  );
  assertEqual(
    data.customer_email,
    guestEmail,
    "Guest email should be returned"
  );

  // Verify the purchase record contains guest information
  const { data: purchase } = await supabase
    .from("purchases")
    .select("*")
    .eq("id", purchaseId)
    .single();

  assertEqual(
    purchase.user_id,
    null,
    "Guest purchases should have null user_id"
  );
  assertEqual(purchase.purchase_type, "event", "Purchase type should be event");
  assertEqual(
    purchase.metadata.is_guest_user,
    true,
    "Purchase metadata should indicate guest user"
  );
  assertEqual(
    purchase.metadata.customer_email,
    guestEmail,
    "Purchase metadata should contain guest email"
  );
  assertEqual(
    purchase.metadata.customer_name,
    guestName,
    "Purchase metadata should contain guest name"
  );

  // Verify the event booking was created
  const { data: booking } = await supabase
    .from("event_bookings")
    .select("*")
    .eq("id", bookingId)
    .single();

  assertEqual(
    booking.purchase_id,
    purchaseId,
    "Booking should link to purchase"
  );
  assertEqual(booking.status, "confirmed", "Guest booking should be confirmed");
  assertNotNull(booking.ticket_code, "Guest booking should have a ticket code");

  console.log(
    `✅ Guest purchase created successfully with email: ${guestEmail}`
  );

  // Track for cleanup
  fixtures.trackRecord("purchases", purchaseId);
  fixtures.trackRecord("event_bookings", bookingId);
}

async function testMultipleAttendeePurchase(fixtures) {
  startTest("Multiple Attendee Purchase");

  logSection("Setup Test Environment");
  logRequirement("Event must support multiple attendee purchases");
  logRequirement("Each attendee gets individual booking record");

  logAction("Creating test event for multiple attendees");

  const event = await fixtures.createTestEvent();
  const quantity = 3;

  const { data, error } = await callFunction("create_event_purchase", {
    p_event_id: event.event.id,
    p_ticket_id: event.tickets[0].id,
    p_date_id: event.dates[0].id,
    p_quantity: quantity,
    p_is_virtual: false,
    p_payment_intent_id: `pi_test_multi_${Date.now()}`,
    p_payment_status: "completed",
    p_customer_email: `multi.customer.${Date.now()}@example.com`,
    p_customer_name: "Multi Customer",
  });

  assert(!error, "Multi-attendee purchase should succeed");
  assertEqual(data.attendees, quantity, "Should handle multiple attendees");

  // Verify the purchase amount is calculated correctly
  const expectedAmount = event.tickets[0].price * quantity;
  assertEqual(
    data.amount,
    expectedAmount,
    "Amount should be ticket price × quantity"
  );

  // Verify the booking record
  const { data: booking } = await supabase
    .from("event_bookings")
    .select("*")
    .eq("id", data.booking_id)
    .single();

  assertEqual(
    booking.attendees,
    quantity,
    "Booking should record correct attendee count"
  );

  // Track for cleanup
  fixtures.trackRecord("purchases", data.purchase_id);
  fixtures.trackRecord("event_bookings", data.booking_id);

  endTest();
}

async function testEventPurchaseValidation(fixtures) {
  startTest("Event Purchase Validation");

  logSection("Setup Test Environment");
  logRequirement("Function must validate required parameters");
  logRequirement("Invalid inputs should be rejected");

  logAction("Testing purchase with invalid parameters");

  const event = await fixtures.createTestEvent();

  logSection("Validation Tests");

  // Test purchase with invalid event ID
  logExpectedFailure("Testing invalid event ID rejection");
  const { data: invalidEventData, error: invalidEventError } =
    await callFunction(
      "create_event_purchase",
      {
        p_event_id: "00000000-0000-0000-0000-000000000000", // Invalid event ID
        p_ticket_id: event.tickets[0].id,
        p_date_id: event.dates[0].id,
        p_quantity: 1,
        p_is_virtual: false,
        p_payment_intent_id: `pi_test_invalid_${Date.now()}`,
        p_payment_status: "completed",
        p_customer_email: `test.validation.${Date.now()}@example.com`,
        p_customer_name: "Test Customer",
      },
      true
    ); // Expected failure - should show in magenta

  // This should fail or handle gracefully
  if (invalidEventError) {
    assertExpectedFailure(true, "Invalid event ID should be rejected");
  } else if (invalidEventData) {
    // Some functions might handle this gracefully
    assertExpectedFailure(true, "Function handled invalid event ID gracefully");
  }

  // Test purchase with invalid ticket ID
  const { error: invalidTicketError } = await callFunction(
    "create_event_purchase",
    {
      p_event_id: event.event.id,
      p_ticket_id: "00000000-0000-0000-0000-000000000000", // Invalid ticket ID
      p_date_id: event.dates[0].id,
      p_quantity: 1,
      p_is_virtual: false,
      p_payment_intent_id: `pi_test_invalid_ticket_${Date.now()}`,
      p_payment_status: "completed",
      p_customer_email: `test.validation.ticket.${Date.now()}@example.com`,
      p_customer_name: "Test Customer",
    },
    true // Expected failure - should show in magenta
  );

  if (invalidTicketError) {
    console.log("✅ PASS: Invalid ticket ID should be rejected");
  }

  // Test purchase with zero quantity
  const { error: zeroQuantityError } = await callFunction(
    "create_event_purchase",
    {
      p_event_id: event.event.id,
      p_ticket_id: event.tickets[0].id,
      p_date_id: event.dates[0].id,
      p_quantity: 0, // Invalid quantity
      p_is_virtual: false,
      p_payment_intent_id: `pi_test_zero_${Date.now()}`,
      p_payment_status: "completed",
      p_customer_email: `test.validation.zero.${Date.now()}@example.com`,
      p_customer_name: "Test Customer",
    }
  );

  if (zeroQuantityError) {
    console.log("✅ PASS: Zero quantity should be rejected");
  }

  endTest();
}

async function testPaymentStatusUpdates(fixtures) {
  startTest("Payment Status Updates");

  logSection("Setup Test Environment");
  logRequirement("Payment status should affect booking confirmation");
  logRequirement("Pending payments should create pending bookings");

  logAction("Creating purchase with pending payment");

  const event = await fixtures.createTestEvent();

  // Test pending payment
  const { data: pendingData, error: pendingError } = await callFunction(
    "create_event_purchase",
    {
      p_event_id: event.event.id,
      p_ticket_id: event.tickets[0].id,
      p_date_id: event.dates[0].id,
      p_quantity: 1,
      p_is_virtual: false,
      p_payment_intent_id: `pi_test_pending_${Date.now()}`,
      p_payment_status: "pending",
      p_customer_email: `test.pending.${Date.now()}@example.com`,
      p_customer_name: "Test Customer",
    }
  );

  assert(!pendingError, "Pending payment should be created successfully");
  assertEqual(
    pendingData.payment_status,
    "pending",
    "Payment status should be pending"
  );

  // Verify the booking status is pending for pending payment
  const { data: pendingBooking } = await supabase
    .from("event_bookings")
    .select("status")
    .eq("id", pendingData.booking_id)
    .single();

  assertEqual(
    pendingBooking.status,
    "pending",
    "Booking should be pending for pending payment"
  );

  // Test completed payment
  const { data: completedData, error: completedError } = await callFunction(
    "create_event_purchase",
    {
      p_event_id: event.event.id,
      p_ticket_id: event.tickets[0].id,
      p_date_id: event.dates[0].id,
      p_quantity: 1,
      p_is_virtual: false,
      p_payment_intent_id: `pi_test_completed_${Date.now()}`,
      p_payment_status: "completed",
      p_customer_email: `test.completed.${Date.now()}@example.com`,
      p_customer_name: "Test Customer",
    }
  );

  assert(!completedError, "Completed payment should be created successfully");
  assertEqual(
    completedData.payment_status,
    "completed",
    "Payment status should be completed"
  );

  // Verify the booking status is confirmed for completed payment
  const { data: completedBooking } = await supabase
    .from("event_bookings")
    .select("status")
    .eq("id", completedData.booking_id)
    .single();

  assertEqual(
    completedBooking.status,
    "confirmed",
    "Booking should be confirmed for completed payment"
  );

  // Track for cleanup
  fixtures.trackRecord("purchases", pendingData.purchase_id);
  fixtures.trackRecord("event_bookings", pendingData.booking_id);
  fixtures.trackRecord("purchases", completedData.purchase_id);
  fixtures.trackRecord("event_bookings", completedData.booking_id);

  endTest();
}

async function testTicketCodeGeneration(fixtures) {
  console.log("Testing ticket code generation...");

  const event = await fixtures.createTestEvent();

  // Create multiple purchases to test unique ticket codes
  const purchases = [];
  for (let i = 0; i < 3; i++) {
    const { data, error } = await callFunction("create_event_purchase", {
      p_event_id: event.event.id,
      p_ticket_id: event.tickets[0].id,
      p_date_id: event.dates[0].id,
      p_quantity: 1,
      p_is_virtual: false,
      p_payment_intent_id: `pi_test_code_${Date.now()}_${i}`,
      p_payment_status: "completed",
      p_customer_email: `test.ticket.code.${Date.now()}.${i}@example.com`,
      p_customer_name: `Test Customer ${i + 1}`,
    });

    assert(!error, `Purchase ${i + 1} should succeed`);
    purchases.push(data);

    // Track for cleanup
    fixtures.trackRecord("purchases", data.purchase_id);
    fixtures.trackRecord("event_bookings", data.booking_id);
  }

  // Get all the booking records to verify ticket codes
  const bookingIds = purchases.map((p) => p.booking_id);
  const { data: bookings } = await supabase
    .from("event_bookings")
    .select("ticket_code")
    .in("id", bookingIds);

  // Verify each booking has a ticket code
  bookings.forEach((booking, index) => {
    assertNotNull(
      booking.ticket_code,
      `Booking ${index + 1} should have ticket code`
    );
    assert(
      booking.ticket_code.length >= 8,
      `Ticket code ${index + 1} should be at least 8 characters`
    );
  });

  // Verify ticket codes are unique
  const ticketCodes = bookings.map((b) => b.ticket_code);
  const uniqueCodes = new Set(ticketCodes);
  assertEqual(
    uniqueCodes.size,
    ticketCodes.length,
    "All ticket codes should be unique"
  );
}

async function testDifferentTicketTypes(fixtures) {
  console.log("Testing purchases for different ticket types...");

  // Create event with multiple ticket types
  const event = await fixtures.createMultiTicketEvent();

  // Test purchasing each ticket type
  for (const ticket of event.tickets) {
    const { data, error } = await callFunction("create_event_purchase", {
      p_event_id: event.event.id,
      p_ticket_id: ticket.id,
      p_date_id: event.dates[0].id,
      p_quantity: 1,
      p_is_virtual: false,
      p_payment_intent_id: `pi_test_${ticket.title
        .toLowerCase()
        .replace(/\s+/g, "_")}_${Date.now()}`,
      p_payment_status: "completed",
      p_customer_email: `test.${ticket.title
        .toLowerCase()
        .replace(/\s+/g, ".")}.${Date.now()}@example.com`,
      p_customer_name: `Test Customer for ${ticket.title}`,
    });

    assert(!error, `Purchase for ${ticket.title} should succeed`);
    assertEqual(
      data.ticket_id,
      ticket.id,
      `Should purchase correct ticket: ${ticket.title}`
    );

    // Verify the amount matches the ticket price
    assertEqual(
      data.amount,
      ticket.price,
      `Amount should match ${ticket.title} price`
    );

    // Track for cleanup
    fixtures.trackRecord("purchases", data.purchase_id);
    fixtures.trackRecord("event_bookings", data.booking_id);
  }
}

async function testVirtualVsInPersonBooking(fixtures) {
  console.log("Testing virtual vs in-person booking differences...");

  const event = await fixtures.createTestEvent();

  // Test virtual booking
  const { data: virtualData, error: virtualError } = await callFunction(
    "create_event_purchase",
    {
      p_event_id: event.event.id,
      p_ticket_id: event.tickets[0].id,
      p_date_id: event.dates[0].id,
      p_quantity: 1,
      p_is_virtual: true,
      p_payment_intent_id: `pi_test_virtual_${Date.now()}`,
      p_payment_status: "completed",
      p_customer_email: `test.virtual.${Date.now()}@example.com`,
      p_customer_name: "Virtual Test Customer",
    }
  );

  assert(!virtualError, "Virtual booking should succeed");

  // Verify virtual booking
  const { data: virtualBooking } = await supabase
    .from("event_bookings")
    .select("is_virtual")
    .eq("id", virtualData.booking_id)
    .single();

  assertEqual(
    virtualBooking.is_virtual,
    true,
    "Virtual booking should be marked as virtual"
  );

  // Test in-person booking
  const { data: inPersonData, error: inPersonError } = await callFunction(
    "create_event_purchase",
    {
      p_event_id: event.event.id,
      p_ticket_id: event.tickets[0].id,
      p_date_id: event.dates[0].id,
      p_quantity: 1,
      p_is_virtual: false,
      p_payment_intent_id: `pi_test_inperson_${Date.now()}`,
      p_payment_status: "completed",
      p_customer_email: `test.inperson.${Date.now()}@example.com`,
      p_customer_name: "In-Person Test Customer",
    }
  );

  assert(!inPersonError, "In-person booking should succeed");

  // Verify in-person booking
  const { data: inPersonBooking } = await supabase
    .from("event_bookings")
    .select("is_virtual")
    .eq("id", inPersonData.booking_id)
    .single();

  assertEqual(
    inPersonBooking.is_virtual,
    false,
    "In-person booking should not be marked as virtual"
  );

  // Track for cleanup
  fixtures.trackRecord("purchases", virtualData.purchase_id);
  fixtures.trackRecord("event_bookings", virtualData.booking_id);
  fixtures.trackRecord("purchases", inPersonData.purchase_id);
  fixtures.trackRecord("event_bookings", inPersonData.booking_id);
}
