import {
  assert,
  assertNotNull,
  startTest,
  endTest,
} from "../../../shared/utilities/test-utils.js";
import { AppointmentFixtures } from "../fixtures.js";

export async function runServiceCreationTests() {
  const fixtures = new AppointmentFixtures();

  try {
    await testBasicServiceCreation(fixtures);
  } finally {
    await fixtures.cleanup();
  }
}

async function testBasicServiceCreation(fixtures) {
  startTest("Create basic service via function");

  const service = await fixtures.createTestService();

  assertNotNull(service.service_id, "Service ID should be returned");

  endTest();
}
