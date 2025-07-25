// Subscription Billing Feature - Cleanup Logic

import { cleanup as packagesCleanup } from "../universal-packages/cleanup.js";
import { log } from "../../shared/utilities/test-utils.js";

/**
 * Clean up all test data created by the subscription billing feature
 * Since this feature reuses universal packages data, delegate to packages cleanup
 * @returns {Promise<number>} Number of records cleaned
 */
export async function cleanup() {
  log("🧹 Starting subscription billing cleanup...", "info");

  // Delegate to packages cleanup since we reuse their data structure
  const totalCleaned = await packagesCleanup();

  log(
    `Subscription billing cleanup completed: ${totalCleaned} records removed`,
    "success"
  );
  return totalCleaned;
}

/**
 * Verify that cleanup was successful
 * @returns {Promise<boolean>} True if cleanup was complete
 */
export async function verify() {
  // Delegate to packages verify since we use their data
  const { verify: packagesVerify } = await import(
    "../universal-packages/cleanup.js"
  );
  return await packagesVerify();
}
