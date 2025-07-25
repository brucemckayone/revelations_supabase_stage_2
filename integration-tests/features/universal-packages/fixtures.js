// Universal Packages Feature - Test Fixtures

import {
  getSingleTestUser,
  getCreatorUser,
  TEST_ROLES,
} from "../../config/test-users.js";
import {
  queryDatabase,
  insertRecord,
  log,
} from "../../shared/utilities/test-utils.js";

/**
 * Test fixtures for Universal Packages feature
 * Creates and manages test data for package tests
 */
export class UniversalPackagesFixtures {
  static processedPaymentIds = new Set();
  constructor() {
    this.createdRecords = [];
    this.testNamePrefix = "TEST_";
    this.purchases = []; // track purchase objects in memory
    // Initialize test users for easy access in tests
    this.testUsers = null;
    this._initializeTestUsers();
  }

  /**
   * Initialize test users for consistent access across tests
   */
  async _initializeTestUsers() {
    try {
      const customer1 = await getSingleTestUser();
      const creator = await getCreatorUser();

      this.testUsers = {
        customer1: customer1,
        creator: creator,
        // Add more test users if needed
      };
    } catch (error) {
      log(`Failed to initialize test users: ${error.message}`, "error");
      // Set fallback structure so tests don't crash
      this.testUsers = {
        customer1: { id: "fallback-user-id" },
        creator: { id: "fallback-creator-id" },
      };
    }
  }

  /**
   * Ensure test users are available
   */
  async _ensureTestUsers() {
    if (!this.testUsers) {
      await this._initializeTestUsers();
    }
    return this.testUsers;
  }

  /**
   * Generate a unique ID for testing
   * @returns {string} Unique ID
   */
  generateUniqueId() {
    return `test_${Date.now()}_${Math.random().toString(36).substring(7)}`;
  }

  /**
   * Generate a test name with proper prefix
   * @param {string} baseName
   * @returns {string}
   */
  generateTestName(baseName) {
    return `${this.testNamePrefix}${baseName}_${Date.now()}`;
  }

  /**
   * Create a test universal package
   * @param {Object} overrides - Package data overrides
   * @returns {Promise<Object>} Created package
   */
  async createTestPackage(overrides = {}) {
    // Use creator user for package creation (required by RLS policies)
    const creator = await getCreatorUser();

    const packageData = {
      creator_id: creator.id,
      name: this.generateTestName("Package"),
      description: "Test package for integration tests",
      // Use actual schema columns - separate credit types
      total_event_credits:
        overrides.credits || overrides.total_event_credits || 5,
      total_appointment_credits: overrides.total_appointment_credits || 0,
      total_content_credits: overrides.total_content_credits || 0,
      // Use price column (exists in schema)
      price: overrides.price || 2000, // $20.00 default
      currency: overrides.currency || "usd",
      // Use actual boolean columns
      is_recurring: overrides.is_recurring || false,
      supports_one_time_purchase:
        overrides.supports_one_time_purchase !== false,
      supports_recurring_purchase:
        overrides.supports_recurring_purchase || false,
      // Use duration columns that exist
      duration_weeks: overrides.duration_weeks || null,
      one_time_duration_weeks: overrides.one_time_duration_weeks, // leave undefined unless provided
      // Set recurring pricing if needed
      one_time_price: overrides.one_time_price || overrides.price || 2000,
      recurring_price: overrides.recurring_price || null,
      // Event access configuration
      event_access_config: overrides.event_access_config || {},
      // Other standard fields
      package_type: overrides.package_type || "custom_bundle",
      is_active: overrides.is_active !== false,
      is_featured: overrides.is_featured || false,
      ...overrides,
    };

    // Validation: ensure package has >0 total credits OR price > 0
    const totalCredits =
      (packageData.total_event_credits || 0) +
      (packageData.total_appointment_credits || 0) +
      (packageData.total_content_credits || 0);

    if (
      totalCredits === 0 &&
      !packageData.one_time_price &&
      !packageData.recurring_price
    ) {
      throw new Error(
        "invalid package configuration: credits and price cannot both be zero"
      );
    }

    // Validation & default for one-time package duration
    if (packageData.supports_one_time_purchase) {
      if (!packageData.one_time_duration_weeks) {
        // If caller explicitly allows missing duration (edge-case tests), throw error
        if (overrides.allow_missing_duration) {
          throw new Error(
            "one_time_duration_weeks required for one-time purchase packages"
          );
        }
        // Otherwise assign sensible default (4 weeks)
        packageData.one_time_duration_weeks = 4;
      }
    }

    // Validation: recurring_price required when supports_recurring_purchase true
    if (
      packageData.supports_recurring_purchase &&
      !packageData.recurring_price
    ) {
      throw new Error(
        "recurring_price required for recurring purchase packages"
      );
    }

    try {
      log(
        `Creating universal package: ${packageData.name} (creator: ${creator.email})`,
        "debug"
      );
      const package_ = await insertRecord("universal_packages", packageData);
      this.createdRecords.push({
        table: "universal_packages",
        id: package_.id,
      });
      log(`Created universal package: ${package_.id}`, "success");
      return package_;
    } catch (error) {
      log(
        `Failed to create universal_packages record: ${error.message}`,
        "error"
      );
      throw error;
    }
  }

  /**
   * Create a test package purchase
   * @param {string} packageId - Package ID to purchase
   * @param {string} userId - User ID (optional, uses test user)
   * @param {Object} overrides - Purchase data overrides
   * @returns {Promise<Object>} Created purchase
   */
  async createTestPackagePurchase(packageId, userId = null, overrides = {}) {
    overrides = overrides || {};
    // First, verify package exists and fetch credits
    const pkgRes = await queryDatabase(
      "SELECT id, total_event_credits, total_appointment_credits, total_content_credits, one_time_duration_weeks FROM universal_packages WHERE id = $1",
      [packageId]
    );

    if (!Array.isArray(pkgRes.data) || pkgRes.data.length === 0) {
      throw new Error("package not found");
    }

    const packageInfo = pkgRes.data[0];

    // Use regular user for purchases unless specified
    const user = userId ? { id: userId } : await getSingleTestUser();

    // Create purchase record first in purchases table
    // For universal packages, we don't set content_id since that references on_demand_media
    // The package is linked through universal_package_purchases table
    const purchaseData = {
      user_id: user.id,
      owner_id: user.id, // Required field based on schema
      purchase_type: "package", // Use correct enum value from purchase_type_enum
      // Do NOT set content_id for packages - it references on_demand_media table
      amount: overrides.amount_paid || overrides.amount || 2000,
      currency: overrides.currency || "usd",
      payment_status: overrides.payment_status || "completed", // Use correct enum value
      stripe_payment_intent_id:
        overrides.stripe_payment_intent_id || `pi_test_${Date.now()}`,
      stripe_customer_id:
        overrides.stripe_customer_id || `cus_test_${Date.now()}`,
    };

    try {
      log(
        `Creating purchase record for package: ${packageId} (user: ${user.id})`,
        "debug"
      );
      const purchase = await insertRecord("purchases", purchaseData);
      this.createdRecords.push({ table: "purchases", id: purchase.id });

      // Calculate expires_at for one-time purchases
      let expiresAt = null;
      if (!overrides.is_recurring && packageInfo.one_time_duration_weeks) {
        const weeksMs =
          packageInfo.one_time_duration_weeks * 7 * 24 * 60 * 60 * 1000;
        expiresAt = new Date(Date.now() + weeksMs).toISOString();
      }

      // Now create the universal package purchase record with correct schema
      const universalPurchaseData = {
        purchase_id: purchase.id,
        package_id: packageId, // This is where the package link goes
        // Use remaining credits columns from schema
        event_credits_remaining: packageInfo.total_event_credits || 0,
        appointment_credits_remaining:
          packageInfo.total_appointment_credits || 0,
        content_credits_remaining: packageInfo.total_content_credits || 0,
        // Set other required fields
        is_recurring: overrides.is_recurring || false,
        status: overrides.status || "active",
        purchase_option:
          overrides.purchase_option ||
          (overrides.is_recurring ? "recurring" : "one_time"),
        activated_at: new Date().toISOString(),
        ...(expiresAt && { expires_at: expiresAt }),
        ...(overrides.current_period_start && {
          current_period_start: overrides.current_period_start,
        }),
        ...(overrides.current_period_end && {
          current_period_end: overrides.current_period_end,
        }),
        ...(overrides.next_billing_date && {
          next_billing_date: overrides.next_billing_date,
        }),
      };

      log(`Creating universal package purchase record`, "debug");
      const universalPurchase = await insertRecord(
        "universal_package_purchases",
        universalPurchaseData
      );
      this.createdRecords.push({
        table: "universal_package_purchases",
        id: universalPurchase.id,
      });

      log(
        `Created universal package purchase: ${universalPurchase.id}`,
        "success"
      );

      // Track in-memory
      this.purchases.push({
        ...universalPurchase,
        user_id: purchase.user_id,
        event_credits_remaining: universalPurchase.event_credits_remaining,
      });

      // Return combined data for test compatibility
      return {
        id: universalPurchase.id,
        purchase_id: purchase.id,
        package_id: packageId, // Use correct field name
        payment_status: purchase.payment_status,
        stripe_payment_intent_id: purchase.stripe_payment_intent_id,
        // Provide both field name formats for compatibility
        event_credits_remaining: universalPurchase.event_credits_remaining,
        remaining_event_credits: universalPurchase.event_credits_remaining, // Alias for tests
        appointment_credits_remaining:
          universalPurchase.appointment_credits_remaining,
        remaining_appointment_credits:
          universalPurchase.appointment_credits_remaining, // Alias for tests
        content_credits_remaining: universalPurchase.content_credits_remaining,
        remaining_content_credits: universalPurchase.content_credits_remaining, // Alias for tests
        amount: purchase.amount, // Use amount from purchases table instead of amount_paid
        user_id: purchase.user_id, // Add user_id for tests
        expires_at: universalPurchase.expires_at,
        ...universalPurchase,
      };
    } catch (error) {
      log(`Failed to create package purchase: ${error.message}`, "error");
      throw error;
    }
  }

  /**
   * Create a complete test scenario with package, purchase, and mock events
   * @param {Object} options - Scenario configuration
   * @returns {Promise<Object>} Complete scenario data
   */
  async createCompletePackageScenario(options = {}) {
    const {
      packageCredits = 5,
      createEvents = 1,
      packagePrice = 2500,
    } = options;

    try {
      log("Creating complete package scenario", "debug");

      const user = await getSingleTestUser();

      // Create package with event credits (creator will be used automatically)
      const package_ = await this.createTestPackage({
        total_event_credits: packageCredits,
        price: packagePrice,
      });

      // Create purchase (regular user)
      const purchase = await this.createTestPackagePurchase(
        package_.id,
        user.id,
        {
          amount: packagePrice,
        }
      );

      // For testing purposes, create mock events instead of real database events
      // This focuses testing on the core universal packages functionality
      const events = [];
      for (let i = 0; i < createEvents; i++) {
        events.push({
          id: `mock-event-${i + 1}-${Date.now()}`,
          name: this.generateTestName(`Event${i + 1}`),
          event_date: {
            id: `mock-date-${i + 1}-${Date.now()}`,
            start_time: new Date(
              Date.now() + 24 * 60 * 60 * 1000
            ).toISOString(),
            end_time: new Date(Date.now() + 25 * 60 * 60 * 1000).toISOString(),
          },
        });
      }

      const scenario = {
        user,
        package: package_,
        purchase,
        events,
      };

      log(
        `Created complete scenario with ${events.length} mock events`,
        "success"
      );
      return scenario;
    } catch (error) {
      log(`Failed to create complete scenario: ${error.message}`, "error");
      throw error;
    }
  }

  /**
   * Create a mock test event for testing (not inserted into database)
   * @param {Object} overrides - Event data overrides
   * @returns {Promise<Object>} Mock event object
   */
  async createTestEvent(overrides = {}) {
    // Create mock event for testing without database insertion
    // This simplifies testing while focusing on universal packages functionality
    log("Creating mock test event for testing", "debug");

    const mockEvent = {
      id: `mock-event-${Date.now()}`,
      title: overrides.name || this.generateTestName("Event"),
      description:
        overrides.description || "Mock test event for integration tests",
      event_type: overrides.event_type || "workshop",
      creator_id: (await getCreatorUser()).id,
      event_date: {
        id: `mock-date-${Date.now()}`,
        start_time:
          overrides.start_time ||
          new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
        end_time:
          overrides.end_time ||
          new Date(Date.now() + 25 * 60 * 60 * 1000).toISOString(),
        timezone: overrides.timezone || "UTC",
        max_attendees: overrides.max_attendees || 10,
      },
    };

    log(`Created mock test event: ${mockEvent.id}`, "success");
    return mockEvent;
  }

  /**
   * Create a recurring package scenario
   * @param {Object} options - Recurring scenario options
   * @returns {Promise<Object>} Recurring scenario data
   */
  async createRecurringPackageScenario(options = {}) {
    const { monthlyCredits = 3, monthlyPrice = 1500 } = options;

    try {
      log("Creating recurring package scenario", "debug");

      const user = await getSingleTestUser();

      // Create recurring package (creator will be used automatically)
      const package_ = await this.createTestPackage({
        total_event_credits: monthlyCredits,
        is_recurring: true,
        supports_recurring_purchase: true,
        recurring_price: monthlyPrice,
        duration_weeks: null, // Ongoing
      });

      // Create recurring purchase (regular user)
      const purchase = await this.createTestPackagePurchase(
        package_.id,
        user.id,
        {
          is_recurring: true,
          purchase_option: "recurring",
          amount_paid: monthlyPrice,
        }
      );

      const scenario = {
        user,
        package: package_,
        purchase,
      };

      log("Created recurring package scenario", "success");
      return scenario;
    } catch (error) {
      log(`Failed to create recurring scenario: ${error.message}`, "error");
      throw error;
    }
  }

  /**
   * Alias for createTestPackagePurchase to match test expectations
   * @param {Object} purchaseData - Purchase configuration
   * @returns {Promise<Object>} Created purchase
   */
  async createTestPurchase(purchaseData) {
    await this._ensureTestUsers();
    return this.createTestPackagePurchase(
      purchaseData.package_id,
      purchaseData.user_id,
      purchaseData
    );
  }

  /**
   * Get a purchase by ID
   * @param {string} purchaseId - Purchase ID
   * @returns {Promise<Object>} Purchase record
   */
  async getPurchase(purchaseId) {
    const result = await queryDatabase(
      `SELECT upp.*, p.user_id
       FROM universal_package_purchases upp
       JOIN purchases p ON upp.purchase_id = p.id
       WHERE upp.id = $1`,
      [purchaseId]
    );

    if (result.error) {
      throw new Error(`Failed to get purchase: ${result.error.message}`);
    }

    if (!result.data || result.data === null) {
      throw new Error("purchase not found");
    }
    if (Array.isArray(result.data) && result.data.length === 0) {
      throw new Error("purchase not found");
    }

    const purchase = result.data[0];
    purchase.remaining_event_credits = purchase.event_credits_remaining;
    purchase.remaining_appointment_credits =
      purchase.appointment_credits_remaining;
    purchase.remaining_content_credits = purchase.content_credits_remaining;
    return purchase;
  }

  /**
   * Get purchases for a user
   * @param {string} userId - User ID
   * @returns {Promise<Array>} Array of purchases
   */
  async getPurchasesForUser(userId) {
    const result = await queryDatabase(
      `SELECT upp.*, p.amount, p.payment_status 
       FROM universal_package_purchases upp 
       JOIN purchases p ON upp.purchase_id = p.id 
       WHERE p.user_id = $1`,
      [userId]
    );

    if (result.error) {
      throw new Error(`Failed to get user purchases: ${result.error.message}`);
    }

    return result.data || [];
  }

  /**
   * Consume event credits from a purchase
   * @param {string} purchaseId - Purchase ID
   * @param {number} creditsToConsume - Number of credits to consume
   * @returns {Promise<Object>} Updated purchase
   */
  async consumeEventCredit(purchaseId, creditsToConsume) {
    // Simple UUID v4 format check to short-circuit obvious invalid IDs used in tests
    if (!/^[0-9a-fA-F-]{36}$/.test(purchaseId)) {
      throw new Error("purchase not found");
    }
    // Atomic update to prevent race conditions and overspending
    const result = await queryDatabase(
      `UPDATE universal_package_purchases
         SET event_credits_remaining = event_credits_remaining - $1
       WHERE id = $2
         AND status = 'active'
         AND (expires_at IS NULL OR expires_at > NOW())
         AND event_credits_remaining >= $1
       RETURNING *`,
      [creditsToConsume, purchaseId]
    );

    if (result.error) {
      // Handle invalid UUID or other bad-input errors by returning clearer message
      const msg = result.error.message || "";
      if (msg.includes("invalid input syntax") || msg.includes("uuid")) {
        throw new Error("purchase not found");
      }
      throw new Error(`failed to consume credits: ${msg}`);
    }

    if (!result.data || result.data.length === 0) {
      // Determine why the update failed – does the purchase exist?
      const check = await queryDatabase(
        "SELECT event_credits_remaining, status, expires_at FROM universal_package_purchases WHERE id = $1",
        [purchaseId]
      );

      if (check.error || !check.data || check.data.length === 0) {
        throw new Error("purchase not found");
      }

      const row = check.data[0];
      if (
        row.status === "expired" ||
        (row.expires_at && new Date(row.expires_at) <= new Date())
      ) {
        throw new Error("purchase expired");
      }

      throw new Error("insufficient credits");
    }

    const updated = result.data[0];
    updated.remaining_event_credits = updated.event_credits_remaining;
    updated.remaining_appointment_credits =
      updated.appointment_credits_remaining;
    updated.remaining_content_credits = updated.content_credits_remaining;

    // update in-memory
    const idx = this.purchases.findIndex((p) => p.id === updated.id);
    if (idx !== -1) {
      const existing = this.purchases[idx];
      this.purchases[idx] = {
        ...existing,
        ...updated,
        user_id: existing.user_id ?? updated.user_id,
      };
    }

    if (!updated) {
      throw new Error("purchase not found");
    }

    return updated;
  }

  /**
   * Consume appointment credits from a purchase
   * @param {string} purchaseId - Purchase ID
   * @param {number} creditsToConsume - Number of credits to consume
   * @returns {Promise<Object>} Updated purchase
   */
  async consumeAppointmentCredit(purchaseId, creditsToConsume) {
    if (!/^[0-9a-fA-F-]{36}$/.test(purchaseId)) {
      throw new Error("purchase not found");
    }
    const result = await queryDatabase(
      `UPDATE universal_package_purchases
         SET appointment_credits_remaining = appointment_credits_remaining - $1
       WHERE id = $2
         AND status = 'active'
         AND (expires_at IS NULL OR expires_at > NOW())
         AND appointment_credits_remaining >= $1
       RETURNING *`,
      [creditsToConsume, purchaseId]
    );

    if (result.error) {
      const msg = result.error.message || "";
      if (msg.includes("invalid input syntax") || msg.includes("uuid")) {
        throw new Error("purchase not found");
      }
      throw new Error(`failed to consume appointment credits: ${msg}`);
    }

    if (!result.data || result.data.length === 0) {
      const check = await queryDatabase(
        "SELECT appointment_credits_remaining, status, expires_at FROM universal_package_purchases WHERE id = $1",
        [purchaseId]
      );

      if (check.error || !check.data || check.data.length === 0) {
        throw new Error("purchase not found");
      }

      const row = check.data[0];
      if (
        row.status === "expired" ||
        (row.expires_at && new Date(row.expires_at) <= new Date())
      ) {
        throw new Error("purchase expired");
      }

      throw new Error("insufficient appointment credits");
    }

    const updated = result.data[0];
    updated.remaining_event_credits = updated.event_credits_remaining;
    updated.remaining_appointment_credits =
      updated.appointment_credits_remaining;
    updated.remaining_content_credits = updated.content_credits_remaining;

    // update in-memory
    const idx = this.purchases.findIndex((p) => p.id === updated.id);
    if (idx !== -1) {
      const existing = this.purchases[idx];
      this.purchases[idx] = {
        ...existing,
        ...updated,
        user_id: existing.user_id ?? updated.user_id,
      };
    }

    if (!updated) {
      throw new Error("purchase not found");
    }

    return updated;
  }

  /**
   * Get total event credits available for a user across all purchases
   * @param {string} userId - User ID
   * @returns {Promise<number>} Total credits available
   */
  async getUserTotalEventCredits(userId) {
    const inMemoryTotal = this.purchases
      .filter((p) => p.user_id === userId)
      .reduce((sum, p) => sum + (p.event_credits_remaining || 0), 0);

    // If we have tracked purchases in memory, prefer that isolated view so that
    // tests remain independent. Only fall back to DB when cache is empty (e.g.,
    // when fixtures were re-created or a scenario explicitly clears cache).
    if (inMemoryTotal > 0 || this.purchases.length > 0) {
      return inMemoryTotal;
    }

    // Fallback: query database for completeness
    const result = await queryDatabase(
      `SELECT COALESCE(SUM(upp.event_credits_remaining), 0) AS total
       FROM universal_package_purchases upp
       JOIN purchases p ON upp.purchase_id = p.id
       WHERE p.user_id = $1`,
      [userId]
    );

    if (result.error) {
      throw new Error(`failed to get total credits: ${result.error.message}`);
    }

    return Number(result.data[0].total) || 0;
  }

  /**
   * Consume credits for a user across their purchases
   * @param {string} userId - User ID
   * @param {number} creditsToConsume - Credits to consume
   * @returns {Promise<void>}
   */
  async consumeUserEventCredits(userId, creditsToConsume) {
    // Prefer in-memory purchases if available (test isolation). Fall back to a DB
    // query only when the cache is empty for this user.
    let purchases = this.purchases.filter((p) => p.user_id === userId);

    if (purchases.length === 0) {
      purchases = await this.getPurchasesForUser(userId);
    }

    let remainingToConsume = creditsToConsume;

    // Consume from purchases with available credits (oldest first)
    for (const purchase of purchases) {
      if (remainingToConsume <= 0) break;

      if (purchase.event_credits_remaining > 0) {
        const toConsume = Math.min(
          purchase.event_credits_remaining,
          remainingToConsume
        );
        const updated = await this.consumeEventCredit(purchase.id, toConsume);
        // Sync in-memory purchase list
        const idx = this.purchases.findIndex((p) => p.id === updated.id);
        if (idx !== -1) {
          const existing = this.purchases[idx];
          this.purchases[idx] = {
            ...existing,
            ...updated,
            user_id: existing.user_id ?? updated.user_id,
          };
        }
        remainingToConsume -= toConsume;
      }
    }

    if (remainingToConsume > 0) {
      throw new Error(
        `Insufficient total credits to consume ${creditsToConsume}`
      );
    }
  }

  /**
   * Process a mock Stripe webhook for testing
   * @param {Object} webhookPayload - Webhook data
   * @returns {Promise<Object>} Processing result
   */
  async processStripeWebhook(webhookPayload) {
    // Mock webhook processing for testing
    log(`Processing mock Stripe webhook: ${webhookPayload.type}`, "debug");

    try {
      if (webhookPayload.type === "checkout.session.completed") {
        const session = webhookPayload.data.object;

        // Duplicate protection
        if (UniversalPackagesFixtures.processedPaymentIds.has(session.id)) {
          log(
            `Duplicate webhook ignored for payment id ${session.id}`,
            "warning"
          );
          return { success: true }; // Idempotent success
        }

        if (session.payment_status === "paid") {
          const purchase = await this.createTestPurchase({
            package_id: session.metadata.package_id,
            user_id: session.metadata.user_id,
            amount: session.amount_total,
            stripe_payment_intent_id: session.id,
          });

          UniversalPackagesFixtures.processedPaymentIds.add(session.id);

          return {
            success: true,
            purchase_id: purchase.id,
          };
        } else {
          return {
            success: false,
            reason: "payment not completed",
          };
        }
      } else if (webhookPayload.type === "customer.subscription.created") {
        const subscription = webhookPayload.data.object;

        if (subscription.status === "active") {
          const purchase = await this.createTestPurchase({
            package_id: subscription.metadata.package_id,
            user_id: subscription.metadata.user_id,
            amount: subscription.plan.amount,
            is_recurring: true,
            purchase_option: "recurring",
          });

          return {
            success: true,
            purchase_id: purchase.id,
          };
        }
      }

      return { success: false, reason: "Webhook type not handled" };
    } catch (error) {
      log(`Webhook processing failed: ${error.message}`, "error");
      return { success: false, error: error.message };
    }
  }

  /**
   * Expire a purchase for testing
   * @param {string} purchaseId - Purchase ID
   * @returns {Promise<Object>} Updated purchase
   */
  async expirePurchase(purchaseId) {
    const expiredDate = new Date(
      Date.now() - 24 * 60 * 60 * 1000
    ).toISOString(); // Yesterday

    const result = await queryDatabase(
      "UPDATE universal_package_purchases SET expires_at = $1, status = 'expired' WHERE id = $2 RETURNING *",
      [expiredDate, purchaseId]
    );

    if (result.error) {
      throw new Error(`Failed to expire purchase: ${result.error.message}`);
    }

    return result.data[0];
  }

  /**
   * Clean up all created test records
   */
  async cleanup() {
    if (this.createdRecords.length === 0) {
      log("No records to clean up", "debug");
      return;
    }

    let totalRemoved = 0;

    // Clean up in reverse order to handle dependencies
    for (const record of this.createdRecords.reverse()) {
      try {
        const result = await queryDatabase(
          `DELETE FROM ${record.table} WHERE id = $1`,
          [record.id]
        );

        if (result.error) {
          log(
            `Failed to delete ${record.table} record ${record.id}: ${result.error.message}`,
            "warn"
          );
        } else {
          totalRemoved++;
          log(`Deleted ${record.table} record: ${record.id}`, "debug");
        }
      } catch (error) {
        log(
          `Error deleting ${record.table} record ${record.id}: ${error.message}`,
          "warn"
        );
      }
    }

    log(
      `Cleanup completed for universal-packages: ${totalRemoved} records removed`,
      "info"
    );
    this.createdRecords = [];
    this.purchases = [];
  }
}
