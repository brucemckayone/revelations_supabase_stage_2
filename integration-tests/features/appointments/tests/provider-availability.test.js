import {
  assertArrayLength,
  assertGreaterThan,
  startTest,
  endTest,
} from "../../../shared/utilities/test-utils.js";
import { AppointmentFixtures } from "../fixtures.js";
import { TEST_CONFIG, supabase } from "../../../config/database.js";

export async function runProviderAvailabilityTests() {
  const fixtures = new AppointmentFixtures();
  try {
    await testWeeklyAvailability(fixtures);
  } finally {
    await fixtures.cleanup();
  }
}

async function testWeeklyAvailability(fixtures) {
  startTest("get_provider_availability should return 7 days of slots");

  const providerId = TEST_CONFIG.CREATOR_USER_ID;
  await fixtures.clearAvailability(providerId);
  await fixtures.setWeeklyAvailability(providerId);

  // Call function for next 7 days
  const today = new Date();
  const startDate = today.toISOString().substring(0, 10); // YYYY-MM-DD
  const endDate = new Date(today.getTime() + 6 * 24 * 60 * 60 * 1000)
    .toISOString()
    .substring(0, 10);

  const { data, error } = await supabase.rpc("get_provider_availability", {
    p_provider_id: providerId,
    p_start_date: startDate,
    p_end_date: endDate,
    p_slot_length_minutes: 30,
  });

  if (error) throw error;

  assertArrayLength(data, 7, "Should return 7 availability rows");
  assertGreaterThan(
    data.filter((d) => d.available_slots.length > 0).length,
    0,
    "At least one day should have slots"
  );

  endTest();
}
