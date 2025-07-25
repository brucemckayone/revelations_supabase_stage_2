import {
  assertEqual,
  assertNotNull,
  startTest,
  endTest,
} from "../../../shared/utilities/test-utils.js";
import { AppointmentFixtures } from "../fixtures.js";
import { getTestUsers } from "../../../config/test-users.js";

export async function runAppointmentBookingTests() {
  const fixtures = new AppointmentFixtures();

  try {
    await testDirectAutoConfirmBooking(fixtures);
    await testPreApprovalBooking(fixtures);
  } finally {
    await fixtures.cleanup();
  }
}

async function testDirectAutoConfirmBooking(fixtures) {
  startTest(
    "Direct workflow with auto-confirm should create confirmed appointment"
  );

  // Create service with direct booking and auto_confirm true
  const serviceRes = await fixtures.createTestService({
    booking_workflow: "direct",
    auto_confirm: true,
    capacity: 10,
  });

  const users = await getTestUsers(1);
  const appointment = await fixtures.createTestAppointment(
    serviceRes.service_id,
    {
      user_id: users[0].id,
      status: "confirmed",
    }
  );

  assertNotNull(appointment.id, "Appointment created");
  assertEqual(
    appointment.status,
    "confirmed",
    "Status should be confirmed for auto-confirm direct workflow"
  );

  endTest();
}

async function testPreApprovalBooking(fixtures) {
  startTest("Pre-approval workflow should create pending_approval appointment");

  const serviceRes = await fixtures.createTestService({
    booking_workflow: "pre-approval",
    auto_confirm: false,
    capacity: 10,
  });

  const users2 = await getTestUsers(1);
  const appointment = await fixtures.createTestAppointment(
    serviceRes.service_id,
    {
      user_id: users2[0].id,
      status: "pending_approval",
    }
  );

  assertNotNull(appointment.id, "Appointment created");
  assertEqual(
    appointment.status,
    "pending_approval",
    "Status should be pending_approval for pre-approval workflow"
  );

  endTest();
}
