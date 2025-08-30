import { TestFixtures } from "../../core/test-framework.js";
import { supabase } from "../../config/database.js";
import { getTestUsers } from "../../config/test-users.js";
import { globalCleanupCoordinator } from "../../shared/utilities/cleanup-coordinator.js";
import { EventsForceCleanup } from "./force-cleanup.js";

export class EventsFixtures extends TestFixtures {
  constructor() {
    super("events");
    // Register with global cleanup coordinator
    globalCleanupCoordinator.registerFixture(this);
  }

  /**
   * Creates tags if they don't exist
   */
  async createTestTags(tagNames, postType = "event") {
    const createdTags = [];

    for (const tagName of tagNames) {
      // Check if tag exists
      const { data: existingTag } = await supabase
        .from("tags")
        .select("id, name")
        .eq("name", tagName)
        .eq("post_type", postType)
        .single();

      if (existingTag) {
        createdTags.push(existingTag);
      } else {
        // Create new tag
        const { data: newTag, error } = await supabase
          .from("tags")
          .insert({
            name: tagName,
            post_type: postType,
          })
          .select()
          .single();

        if (error) throw error;
        this.trackRecord("tags", newTag.id);
        createdTags.push(newTag);
      }
    }

    return createdTags;
  }

  /**
   * Manually creates post_tags associations (workaround for broken add_tags_to_post function)
   */
  async createPostTagAssociations(postId, tagNames) {
    const tags = await this.createTestTags(tagNames);

    for (const tag of tags) {
      const { error } = await supabase
        .from("post_tags")
        .insert({
          post_id: postId,
          tag_id: tag.id,
        })
        .single();

      if (error && !error.message.includes("duplicate")) {
        throw error;
      }
    }

    return tags;
  }

  /**
   * Creates a test event with posts, dates, and tickets
   */
  async createTestEvent(overrides = {}) {
    const timestamp = Date.now();
    const testUsers = await getTestUsers(1);
    const creatorId = testUsers[0].id;

    // Create tags first if provided
    const tags = overrides.tags || ["test", "integration"];
    await this.createTestTags(tags);

    // Create post first
    const postData = {
      title: `TEST_Event_${timestamp}`,
      slug: `test-event-${timestamp}`,
      description: "Test event description",
      content: "Test event content",
      post_type: "event",
      status: "public",
      thumbnail_url: `https://example.com/test-thumbnail-${timestamp}.jpg`,
      user_id: creatorId,
      ...overrides.post,
    };

    const { data: post, error: postError } = await supabase
      .from("posts")
      .insert(postData)
      .select()
      .single();

    if (postError) throw postError;
    this.trackRecord("posts", post.id);

    // Create event
    const eventData = {
      post_id: post.id,
      content: postData.content,
      type: "online",
      ...overrides.event,
    };

    const { data: event, error: eventError } = await supabase
      .from("events")
      .insert(eventData)
      .select()
      .single();

    if (eventError) throw eventError;
    this.trackRecord("events", event.id, {
      parentTable: "posts",
      parentId: post.id,
    });

    // Create default event dates if not provided
    const dates = overrides.dates || [
      {
        start_date: new Date(
          Date.now() + 7 * 24 * 60 * 60 * 1000
        ).toISOString(), // 1 week from now
        end_date: new Date(
          Date.now() + 7 * 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000
        ).toISOString(), // 2 hours duration
      },
    ];

    const eventDates = [];
    for (const dateData of dates) {
      const { data: eventDate, error: dateError } = await supabase
        .from("event_dates")
        .insert({
          event_id: event.id,
          ...dateData,
        })
        .select()
        .single();

      if (dateError) throw dateError;
      this.trackRecord("event_dates", eventDate.id, {
        parentTable: "events",
        parentId: event.id,
      });
      eventDates.push(eventDate);
    }

    // Create default tickets if not provided
    const tickets = overrides.tickets || [
      {
        title: "General Admission",
        description: "General admission ticket",
        price: 2500, // $25.00
        quantity: 100,
      },
    ];

    const eventTickets = [];
    for (const ticketData of tickets) {
      const { data: ticket, error: ticketError } = await supabase
        .from("tickets")
        .insert({
          event_id: event.id,
          ...ticketData,
        })
        .select()
        .single();

      if (ticketError) throw ticketError;
      this.trackRecord("tickets", ticket.id, {
        parentTable: "events",
        parentId: event.id,
      });
      eventTickets.push(ticket);
    }

    return {
      post,
      event,
      dates: eventDates,
      tickets: eventTickets,
      creator: testUsers[0],
    };
  }

  /**
   * Creates a test event purchase using the create_event_purchase function
   */
  async createTestEventPurchase(eventId, ticketId, dateId, overrides = {}) {
    const {
      quantity = 1,
      isVirtual = false,
      paymentIntentId = `test_payment_${Date.now()}`,
      paymentStatus = "completed",
      customerEmail = null, // If null, will use authenticated user
      customerName = null,
      useAuthentication = true, // NEW: Control whether to use auth or guest purchase
    } = overrides;

    let result;

    if (useAuthentication && !customerEmail) {
      // Use authenticated user (original behavior)
      const testUsers = await getTestUsers(1);

      // Set authentication context for Supabase
      const { error: authError } = await supabase.auth.signInWithPassword({
        email: testUsers[0].email,
        password: "test-password", // This won't work in practice, but simulates auth
      });

      // For testing, we'll call the function directly
      const { data, error } = await supabase.rpc("create_event_purchase", {
        p_event_id: eventId,
        p_ticket_id: ticketId,
        p_date_id: dateId,
        p_quantity: quantity,
        p_is_virtual: isVirtual,
        p_payment_intent_id: paymentIntentId,
        p_payment_status: paymentStatus,
        p_customer_email: null, // Authenticated users don't need email
        p_customer_name: null,
      });

      if (error) throw error;
      result = { ...data, user: testUsers[0] };
    } else {
      // Use guest purchase (new behavior)
      const guestEmail =
        customerEmail || `test.guest.${Date.now()}@example.com`;
      const guestName = customerName || "Test Guest";

      const { data, error } = await supabase.rpc("create_event_purchase", {
        p_event_id: eventId,
        p_ticket_id: ticketId,
        p_date_id: dateId,
        p_quantity: quantity,
        p_is_virtual: isVirtual,
        p_payment_intent_id: paymentIntentId,
        p_payment_status: paymentStatus,
        p_customer_email: guestEmail,
        p_customer_name: guestName,
      });

      if (error) throw error;
      result = {
        ...data,
        guest: { email: guestEmail, name: guestName },
        is_guest_purchase: true,
      };
    }

    // Track for cleanup with proper dependencies
    this.trackRecord("purchases", result.purchase_id);
    this.trackRecord("event_bookings", result.booking_id, {
      parentTable: "purchases",
      parentId: result.purchase_id,
    });

    return result;
  }

  /**
   * Creates a test universal package for event credits
   */
  async createTestEventPackage(overrides = {}) {
    const testUsers = await getTestUsers(1);
    const creatorId = testUsers[0].id;

    const packageData = {
      name: `TEST_EventPackage_${Date.now()}`,
      description: "Test event package with credits",

      // Legacy columns (for backward compatibility)
      price: 10000, // $100.00
      duration_weeks: 12, // 3 months = 12 weeks
      is_recurring: false,

      // New dual purchase columns (required by constraints)
      supports_one_time_purchase: true,
      supports_recurring_purchase: false,
      one_time_price: 10000, // $100.00
      one_time_duration_weeks: 12, // 3 months = 12 weeks
      recurring_price: null,

      // Credit columns (using the correct names from schema)
      total_appointment_credits: 0,
      total_content_credits: 0,
      total_event_credits: 5,

      creator_id: creatorId,
      configuration: {
        test_package: true,
        ...overrides.metadata,
      },
      ...overrides,
    };

    const { data: package_, error } = await supabase
      .from("universal_packages")
      .insert(packageData)
      .select()
      .single();

    if (error) throw error;
    this.trackRecord("universal_packages", package_.id);
    return package_;
  }

  /**
   * Get a test user ID for consistent user operations
   */
  async getTestUserId() {
    const testUsers = await getTestUsers(1);
    return testUsers[0].id;
  }

  /**
   * Creates a test universal package purchase
   */
  async createTestPackagePurchase(packageId, overrides = {}) {
    const testUsers = await getTestUsers(1);
    const userId = overrides.user_id || testUsers[0].id;

    // Get package details
    const { data: package_ } = await supabase
      .from("universal_packages")
      .select("*")
      .eq("id", packageId)
      .single();

    // Create purchase record for the package
    const purchaseData = {
      user_id: userId, // This will be overridden by overrides.user_id if provided
      owner_id: package_.creator_id,
      amount: package_.price,
      currency: "usd",
      payment_status: "completed",
      purchase_type: "package",
      quantity: 1,
      metadata: {
        package_id: packageId,
        test_purchase: true,
      },
      // Don't include package-specific fields in purchase data
      ...(({ event_credits_remaining, expires_at, ...rest }) => rest)(
        overrides
      ),
    };

    const { data: purchase, error: purchaseError } = await supabase
      .from("purchases")
      .insert(purchaseData)
      .select()
      .single();

    if (purchaseError) throw purchaseError;
    this.trackRecord("purchases", purchase.id);

    // Create package purchase
    const packagePurchaseData = {
      package_id: packageId,
      purchase_id: purchase.id,
      // Note: user_id is tracked through purchase_id -> purchases.user_id (not directly in this table)
      status: "active",
      purchase_option: "one_time",
      event_credits_remaining:
        overrides.event_credits_remaining ?? package_.total_event_credits,
      appointment_credits_remaining:
        overrides.appointment_credits_remaining ??
        package_.total_appointment_credits,
      content_credits_remaining:
        overrides.content_credits_remaining ?? package_.total_content_credits,
      expires_at: new Date(
        Date.now() + package_.duration_weeks * 7 * 24 * 60 * 60 * 1000
      ).toISOString(),
      // Remove user_id from overrides since it doesn't exist in this table
      ...(({ user_id, ...rest }) => rest)(overrides),
    };

    const { data: packagePurchase, error: packagePurchaseError } =
      await supabase
        .from("universal_package_purchases")
        .insert(packagePurchaseData)
        .select()
        .single();

    if (packagePurchaseError) throw packagePurchaseError;
    this.trackRecord("universal_package_purchases", packagePurchase.id, {
      parentTable: "purchases",
      parentId: purchase.id,
    });

    return { purchase, packagePurchase, package_, user: testUsers[0] };
  }

  /**
   * Creates a limited capacity event for testing capacity limits
   */
  async createLimitedCapacityEvent(capacity = 2) {
    const timestamp = Date.now();
    return this.createTestEvent({
      tickets: [
        {
          title: `Limited Ticket ${timestamp}`,
          description: "Limited capacity ticket for testing",
          price: 1000, // $10.00
          quantity: capacity,
        },
      ],
    });
  }

  /**
   * Creates an event with multiple ticket types
   */
  async createMultiTicketEvent() {
    return this.createTestEvent({
      tickets: [
        {
          title: "Early Bird",
          description: "Early bird special pricing",
          price: 2000, // $20.00
          quantity: 50,
        },
        {
          title: "General Admission",
          description: "Regular ticket pricing",
          price: 3000, // $30.00
          quantity: 100,
        },
        {
          title: "VIP",
          description: "VIP access with extras",
          price: 5000, // $50.00
          quantity: 20,
        },
      ],
    });
  }

  /**
   * Creates an event with multiple dates
   */
  async createMultiDateEvent() {
    const now = Date.now();
    return this.createTestEvent({
      dates: [
        {
          start_date: new Date(now + 7 * 24 * 60 * 60 * 1000).toISOString(),
          end_date: new Date(
            now + 7 * 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000
          ).toISOString(),
        },
        {
          start_date: new Date(now + 14 * 24 * 60 * 60 * 1000).toISOString(),
          end_date: new Date(
            now + 14 * 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000
          ).toISOString(),
        },
        {
          start_date: new Date(now + 21 * 24 * 60 * 60 * 1000).toISOString(),
          end_date: new Date(
            now + 21 * 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000
          ).toISOString(),
        },
      ],
    });
  }

  /**
   * Enhanced cleanup method that handles events-specific constraints
   */
  async cleanup() {
    try {
      // Use the parent class cleanup which now has improved dependency handling
      const result = await super.cleanup();

      // If nothing was cleaned, records might still exist due to constraints
      if (result === 0 && this.getCleanupStatus().totalRecords > 0) {
        console.log(
          "Standard cleanup cleaned 0 records, trying force cleanup..."
        );
        const forceResult = await EventsForceCleanup.forceCleanAllTestData(1);
        globalCleanupCoordinator.unregisterFixture(this);
        return forceResult;
      }

      // Unregister from global coordinator when done
      globalCleanupCoordinator.unregisterFixture(this);
      return result;
    } catch (error) {
      // If cleanup fails, try force cleanup for events
      console.warn(
        `Standard cleanup failed for events, attempting force cleanup: ${error.message}`
      );

      try {
        const result = await EventsForceCleanup.forceCleanAllTestData(1);
        globalCleanupCoordinator.unregisterFixture(this);
        return result;
      } catch (forceError) {
        console.error(`Force cleanup also failed: ${forceError.message}`);
        globalCleanupCoordinator.unregisterFixture(this);
        return 0;
      }
    }
  }
}
