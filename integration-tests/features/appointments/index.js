import { TestSuite } from "../../core/test-framework.js";
import { runServiceCreationTests } from "./tests/service-creation.test.js";
import { runAppointmentBookingTests } from "./tests/appointment-booking.test.js";
import { runProviderAvailabilityTests } from "./tests/provider-availability.test.js";
import { runWaitlistTests } from "./tests/waitlist.test.js";

export const metadata = {
  name: "Appointments",
  description:
    "Tests for services, appointments, packages, and related workflows (capacity, waitlist, etc.)",
  dependencies: [], // Independent feature
  cleanup_order: 2, // Clean after universal-packages (3) but before others
};

export async function runTests() {
  const suite = new TestSuite(metadata.name, metadata.description);

  suite.addTest("Service Creation Tests", runServiceCreationTests);
  suite.addTest("Appointment Booking Tests", runAppointmentBookingTests);
  suite.addTest("Provider Availability Tests", runProviderAvailabilityTests);
  suite.addTest("Waitlist Tests", runWaitlistTests);

  return await suite.run();
}

// Cleanup will be provided by separate cleanup.js file
export { cleanup } from "./cleanup.js";
