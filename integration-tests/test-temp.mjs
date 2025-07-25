import { UniversalPackagesFixtures } from "./features/universal-packages/fixtures.js";

const fixtures = new UniversalPackagesFixtures();
const fakeId = `test_${Date.now()}`;
try {
  await fixtures.consumeEventCredit(fakeId, 1);
} catch (e) {
  console.log("Error message:", e.message);
}
