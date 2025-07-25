// Universal Packages - Test Suite Index
// Organizes all universal packages tests into modular, focused test files

import { createPackageCreationTests } from "./package-creation.test.js";
import { createPackagePurchasingTests } from "./package-purchasing.test.js";
import { createCreditConsumptionTests } from "./credit-consumption.test.js";
import { createWebhookProcessingTests } from "./webhook-processing.test.js";
import { createEdgeCasesTests } from "./edge-cases.test.js";

/**
 * UNIVERSAL PACKAGES TEST ORGANIZATION
 *
 * This file organizes universal packages tests into focused, maintainable modules:
 *
 * 📦 package-creation.test.js - Package configuration and creation
 * 💳 package-purchasing.test.js - Purchase creation and validation
 * 🎯 credit-consumption.test.js - Credit usage and tracking
 * 🔗 webhook-processing.test.js - Stripe webhook handling
 * ⚠️  edge-cases.test.js - Error handling and boundary conditions
 *
 * BENEFITS OF THIS STRUCTURE:
 * - Easy to find and modify specific test areas
 * - Tests can be run individually for faster debugging
 * - Clear separation of concerns
 * - Scalable as new features are added
 * - Better parallel test execution potential
 */

export function createUniversalPackagesTests() {
  return [
    createPackageCreationTests(),
    createPackagePurchasingTests(),
    createCreditConsumptionTests(),
    createWebhookProcessingTests(),
    createEdgeCasesTests(),
  ];
}
