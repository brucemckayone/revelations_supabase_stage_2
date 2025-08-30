import { TestFixtures } from "../../core/test-framework.js";
import { supabase } from "../../config/database.js";
import { TestUserManager } from "../../shared/utilities/test-user-manager.js";

export class NotificationsFixtures extends TestFixtures {
  constructor() {
    super("notifications");
    this.userManager = new TestUserManager();
  }

  /**
   * Creates a test notification
   */
  async createTestNotification(overrides = {}) {
    const { user } = await this.userManager.asUser(
      process.env.TEST_USER_EMAIL || "brucemckayone@gmail.com",
      process.env.TEST_USER_PASSWORD || "password123"
    );

    const notificationData = {
      user_id: user.id,
      title: `TEST_Notification_${Date.now()}`,
      content: "This is a test notification for system testing",
      type: "general",
      action_url: "/test-action",
      reference_type: "test",
      metadata: {
        test_created_at: new Date().toISOString(),
        test_type: "automated_test",
      },
      ...overrides,
    };

    const { data, error } = await supabase
      .from("notifications")
      .insert(notificationData)
      .select()
      .single();

    if (error) throw error;

    this.trackRecord("notifications", data.id);
    return data;
  }

  /**
   * Creates a test email template
   */
  async createTestEmailTemplate(overrides = {}) {
    const templateData = {
      name: `TEST_EmailTemplate_${Date.now()}`,
      subject: "Test Email Template - {{title}}",
      html_content: `
        <html>
          <body>
            <h1>{{title}}</h1>
            <p>{{content}}</p>
            <a href="{{action_url}}">Take Action</a>
          </body>
        </html>
      `,
      text_content: "{{title}}\n\n{{content}}\n\nAction: {{action_url}}",
      variables: ["title", "content", "action_url"],
      is_active: true,
      ...overrides,
    };

    const { data, error } = await supabase
      .from("email_templates")
      .insert(templateData)
      .select()
      .single();

    if (error) throw error;

    this.trackRecord("email_templates", data.id);
    return data;
  }

  /**
   * Creates a test notification template
   */
  async createTestNotificationTemplate(overrides = {}) {
    const { user } = await this.userManager.asUser(
      process.env.TEST_USER_EMAIL || "brucemckayone@gmail.com",
      process.env.TEST_USER_PASSWORD || "password123"
    );

    const templateData = {
      creator_id: user.id,
      title: `TEST_Template_${Date.now()}`,
      content: "Test notification template content",
      type: "system", // Use valid notification type
      action_url: "/template-action",
      metadata: {
        test_template: true,
        created_at: new Date().toISOString(),
      },
      ...overrides,
    };

    const { data, error } = await supabase
      .from("notification_templates")
      .insert(templateData)
      .select()
      .single();

    if (error) throw error;

    this.trackRecord("notification_templates", data.id);
    return data;
  }

  /**
   * Creates test notification preferences for a user
   */
  async createTestNotificationPreferences(userId, overrides = {}) {
    const preferencesData = {
      user_id: userId,
      type: "system", // Valid types: appointment, message, system, payment, reminder
      in_app: true,
      email: true,
      push: false,
      sms: false,
      ...overrides,
    };

    const { data, error } = await supabase
      .from("notification_preferences")
      .insert(preferencesData)
      .select()
      .single();

    if (error) throw error;

    this.trackRecord("notification_preferences", data.id);
    return data;
  }

  /**
   * Creates a test FCM token for push notifications
   */
  async createTestFCMToken(userId, overrides = {}) {
    const tokenData = {
      user_id: userId,
      token: `TEST_FCM_TOKEN_${Date.now()}_${Math.random()
        .toString(36)
        .substr(2, 9)}`,
      device_info: {
        platform: "test",
        app_version: "1.0.0",
        device_model: "test-device",
      },
      is_active: true,
      last_used_at: new Date().toISOString(),
      ...overrides,
    };

    const { data, error } = await supabase
      .from("user_fcm_tokens")
      .insert(tokenData)
      .select()
      .single();

    if (error) throw error;

    this.trackRecord("user_fcm_tokens", data.id);
    return data;
  }

  /**
   * Creates a test notification delivery record
   */
  async createTestNotificationDelivery(notificationId, overrides = {}) {
    const deliveryData = {
      notification_id: notificationId,
      channel: "email",
      status: "pending",
      attempt_count: 0,
      ...overrides,
    };

    const { data, error } = await supabase
      .from("notification_deliveries")
      .insert(deliveryData)
      .select()
      .single();

    if (error) throw error;

    this.trackRecord("notification_deliveries", data.id);
    return data;
  }

  /**
   * Creates a test event for notification triggers
   */
  async createTestEvent(overrides = {}) {
    const { user } = await this.userManager.asUser(
      process.env.TEST_USER_EMAIL || "brucemckayone@gmail.com",
      process.env.TEST_USER_PASSWORD || "password123"
    );

    // First create a post
    const postData = {
      user_id: user.id,
      title: `TEST_Event_${Date.now()}`,
      slug: `test-event-${Date.now()}`,
      description: "Test event for notification testing",
      content: "This is a test event",
      post_type: "event",
      status: "public",
      ...overrides.post,
    };

    const { data: post, error: postError } = await supabase
      .from("posts")
      .insert(postData)
      .select()
      .single();

    if (postError) throw postError;
    this.trackRecord("posts", post.id);

    // Create the event
    const eventData = {
      post_id: post.id,
      content: "Additional event content",
      type: "online",
      ...overrides.event,
    };

    const { data: event, error: eventError } = await supabase
      .from("events")
      .insert(eventData)
      .select()
      .single();

    if (eventError) throw eventError;
    this.trackRecord("events", event.id);

    return { post, event };
  }

  /**
   * Gets test user ID with authentication
   */
  async getTestUserId() {
    const { user } = await this.userManager.asUser(
      process.env.TEST_USER_EMAIL || "brucemckayone@gmail.com",
      process.env.TEST_USER_PASSWORD || "password123"
    );
    return user.id;
  }

  /**
   * Creates a complete notification setup for testing
   */
  async createNotificationTestSetup() {
    const userId = await this.getTestUserId();

    // Create notification
    const notification = await this.createTestNotification({ user_id: userId });

    // Create delivery records for all channels
    const deliveries = {
      email: await this.createTestNotificationDelivery(notification.id, {
        channel: "email",
      }),
      push: await this.createTestNotificationDelivery(notification.id, {
        channel: "push",
      }),
      in_app: await this.createTestNotificationDelivery(notification.id, {
        channel: "in_app",
      }),
    };

    // Create preferences
    const preferences = await this.createTestNotificationPreferences(userId);

    // Create FCM token
    const fcmToken = await this.createTestFCMToken(userId);

    return {
      notification,
      deliveries,
      preferences,
      fcmToken,
      userId,
    };
  }
}
