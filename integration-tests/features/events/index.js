import { TestSuite } from "../../core/test-framework.js";
import { runEventCreationTests } from "./tests/event-creation.test.js";
import { runEventBookingTests } from "./tests/event-booking.test.js";
import { runEventCreditsTests } from "./tests/event-credits.test.js";
import { runEventCapacityTests } from "./tests/event-capacity.test.js";
import { runEventCancellationTests } from "./tests/event-cancellation.test.js";
import { runEventCancellationComprehensiveTests } from "./tests/event-cancellation-comprehensive.test.js";
import { cleanup } from "./cleanup.js";

export const metadata = {
  name: "Events System",
  description:
    "Tests for event creation, booking, universal package integration, and capacity management",
  dependencies: [], // Events can run standalone
  cleanup_order: 2, // Clean up before universal packages (which may depend on events)
};

export async function runTests() {
  const suite = new TestSuite(metadata.name, metadata.description);

  // Test creation and management functions
  suite.addTest("Event Creation & Management Tests", runEventCreationTests);

  // Test traditional event booking with purchases
  suite.addTest("Event Booking & Purchase Tests", runEventBookingTests);

  // Test event booking with universal package credits
  suite.addTest("Universal Package Credits Tests", runEventCreditsTests);

  // Test capacity limits, availability, and waitlist functionality
  suite.addTest("Event Capacity & Availability Tests", runEventCapacityTests);

  // Test advanced cancellation and refund workflows
  suite.addTest("Event Cancellation & Refund Tests", runEventCancellationTests);

  // COMPREHENSIVE TEST SUITE: Complete specification for cancellation workflows
  // These tests will initially FAIL until database functions are implemented
  suite.addTest(
    "🧪 COMPREHENSIVE Cancellation Specification",
    runEventCancellationComprehensiveTests
  );

  return await suite.run();
}

export { cleanup };
