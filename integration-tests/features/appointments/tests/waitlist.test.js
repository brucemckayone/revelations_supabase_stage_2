import {
  assertEqual,
  assertNotNull,
  startTest,
  endTest,
} from "../../../shared/utilities/test-utils.js";
import { AppointmentFixtures } from "../fixtures.js";
import { getTestUsers } from "../../../config/test-users.js";
import { supabase } from "../../../config/database.js";

export async function runWaitlistTests() {
  const fixtures = new AppointmentFixtures();
  try {
    await testWaitlistJoinAndNotify(fixtures);
    await testWaitlistClaim(fixtures);
  } finally {
    await fixtures.cleanup();
  }
}

let cachedWaitlistEntryId;
let serviceId;
let user;

async function testWaitlistJoinAndNotify(fixtures) {
  startTest("User joins waitlist and gets notified when capacity frees up");

  [user] = await getTestUsers(1);

  // Create service with capacity 1 and current_bookings 1 to trigger waitlist
  const res = await fixtures.createTestService({
    capacity: 1,
    current_bookings: 1,
    waitlist_enabled: true,
  });
  serviceId = res.service_id;

  // Ensure service reflects current_bookings 1
  await supabase
    .from("services")
    .update({ current_bookings: 1 })
    .eq("id", serviceId);

  const waitlistEntry = await fixtures.joinWaitlist(user.id, serviceId);
  cachedWaitlistEntryId = waitlistEntry.id;
  assertEqual(
    waitlistEntry.status,
    "waiting",
    "Entry should be waiting initially"
  );

  // Free up capacity: set current_bookings to 0
  await supabase
    .from("services")
    .update({ current_bookings: 0 })
    .eq("id", serviceId);

  // Run processor
  await fixtures.checkCapacityAndNotify(serviceId);

  const { data: updatedEntry } = await supabase
    .from("waitlist_entries")
    .select("status")
    .eq("id", cachedWaitlistEntryId)
    .single();

  assertEqual(updatedEntry.status, "notified", "Entry should be notified");
  endTest();
}

async function testWaitlistClaim(fixtures) {
  startTest("User claims waitlist spot");
  assertNotNull(
    cachedWaitlistEntryId,
    "Previous test should set waitlist entry id"
  );

  await fixtures.claimWaitlistSpot(cachedWaitlistEntryId, user.id);

  const { data: entry } = await supabase
    .from("waitlist_entries")
    .select("status")
    .eq("id", cachedWaitlistEntryId)
    .single();

  assertEqual(entry.status, "claimed", "Status should be claimed");
  endTest();
}
