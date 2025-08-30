/**
 * Notification Delivery Stubs
 *
 * Mock implementations of edge functions for testing notification delivery
 * without actually sending emails or push notifications
 */

import { supabase } from "../../../config/database.js";

export class NotificationStubs {
  constructor() {
    this.sentEmails = [];
    this.sentPushNotifications = [];
    this.deliveryAttempts = new Map();
    this.failureSimulations = new Map();
  }

  /**
   * Simulates the send-notification-email edge function
   */
  async processEmailNotifications(limit = 10) {
    // Get pending email notifications
    const { data: pendingDeliveries, error: deliveryError } = await supabase
      .from("notification_deliveries")
      .select(
        `
        id,
        notification_id,
        attempt_count,
        notifications(
          id,
          user_id,
          title,
          content,
          type,
          action_url,
          metadata
        )
      `
      )
      .eq("channel", "email")
      .eq("status", "pending")
      .lt("attempt_count", 3)
      .order("created_at", { ascending: true })
      .limit(limit);

    if (deliveryError) {
      throw new Error(
        `Error fetching pending deliveries: ${deliveryError.message}`
      );
    }

    if (!pendingDeliveries || pendingDeliveries.length === 0) {
      return { processed: 0, sent: 0, failed: 0 };
    }

    const results = {
      processed: 0,
      sent: 0,
      failed: 0,
      details: [],
    };

    for (const delivery of pendingDeliveries) {
      results.processed++;

      // Track attempt
      const attemptKey = `${delivery.notification_id}_email`;
      const attempts = (this.deliveryAttempts.get(attemptKey) || 0) + 1;
      this.deliveryAttempts.set(attemptKey, attempts);

      // Update to processing
      await supabase
        .from("notification_deliveries")
        .update({
          status: "processing",
          attempt_count: attempts,
          updated_at: new Date().toISOString(),
        })
        .eq("id", delivery.id);

      // Simulate failure if configured
      if (this.shouldSimulateFailure(delivery.id)) {
        await this.markDeliveryFailed(
          delivery.id,
          "Simulated failure for testing"
        );
        results.failed++;
        results.details.push({
          id: delivery.id,
          status: "failed",
          error: "Simulated failure",
        });
        continue;
      }

      // Get user email (mock)
      const { data: userData } = await supabase
        .from("auth.users")
        .select("email")
        .eq("id", delivery.notifications.user_id)
        .single();

      // Record sent email
      this.sentEmails.push({
        deliveryId: delivery.id,
        notificationId: delivery.notification_id,
        userId: delivery.notifications.user_id,
        email: userData?.email || "test@example.com",
        title: delivery.notifications.title,
        content: delivery.notifications.content,
        type: delivery.notifications.type,
        sentAt: new Date().toISOString(),
        attempt: attempts,
      });

      // Mark as sent
      await supabase
        .from("notification_deliveries")
        .update({
          status: "sent",
          external_id: `mock_email_${Date.now()}_${delivery.id}`,
          updated_at: new Date().toISOString(),
        })
        .eq("id", delivery.id);

      results.sent++;
      results.details.push({
        id: delivery.id,
        status: "sent",
        mockId: `mock_email_${delivery.id}`,
      });
    }

    return results;
  }

  /**
   * Simulates the send-notification-push edge function
   */
  async processPushNotifications(limit = 10) {
    // Get pending push notifications
    const { data: pendingDeliveries, error: deliveryError } = await supabase
      .from("notification_deliveries")
      .select(
        `
        id,
        notification_id,
        attempt_count,
        notifications(
          id,
          user_id,
          title,
          content,
          type,
          action_url,
          metadata
        )
      `
      )
      .eq("channel", "push")
      .eq("status", "pending")
      .lt("attempt_count", 3)
      .order("created_at", { ascending: true })
      .limit(limit);

    if (deliveryError) {
      throw new Error(
        `Error fetching pending deliveries: ${deliveryError.message}`
      );
    }

    if (!pendingDeliveries || pendingDeliveries.length === 0) {
      return { processed: 0, sent: 0, failed: 0 };
    }

    const results = {
      processed: 0,
      sent: 0,
      failed: 0,
      details: [],
    };

    for (const delivery of pendingDeliveries) {
      results.processed++;

      // Track attempt
      const attemptKey = `${delivery.notification_id}_push`;
      const attempts = (this.deliveryAttempts.get(attemptKey) || 0) + 1;
      this.deliveryAttempts.set(attemptKey, attempts);

      // Update to processing
      await supabase
        .from("notification_deliveries")
        .update({
          status: "processing",
          attempt_count: attempts,
          updated_at: new Date().toISOString(),
        })
        .eq("id", delivery.id);

      // Simulate failure if configured
      if (this.shouldSimulateFailure(delivery.id)) {
        await this.markDeliveryFailed(delivery.id, "Simulated push failure");
        results.failed++;
        results.details.push({
          id: delivery.id,
          status: "failed",
          error: "Simulated failure",
        });
        continue;
      }

      // Get user FCM tokens
      const { data: tokens } = await supabase
        .from("user_fcm_tokens")
        .select("token")
        .eq("user_id", delivery.notifications.user_id)
        .eq("is_active", true);

      if (!tokens || tokens.length === 0) {
        await this.markDeliveryFailed(delivery.id, "No active FCM tokens");
        results.failed++;
        results.details.push({
          id: delivery.id,
          status: "failed",
          error: "No active FCM tokens",
        });
        continue;
      }

      // Record sent push notification
      this.sentPushNotifications.push({
        deliveryId: delivery.id,
        notificationId: delivery.notification_id,
        userId: delivery.notifications.user_id,
        tokens: tokens.map((t) => t.token),
        title: delivery.notifications.title,
        content: delivery.notifications.content,
        type: delivery.notifications.type,
        sentAt: new Date().toISOString(),
        attempt: attempts,
      });

      // Mark as sent
      await supabase
        .from("notification_deliveries")
        .update({
          status: "sent",
          external_id: `mock_push_${Date.now()}_${delivery.id}`,
          updated_at: new Date().toISOString(),
        })
        .eq("id", delivery.id);

      results.sent++;
      results.details.push({
        id: delivery.id,
        status: "sent",
        mockId: `mock_push_${delivery.id}`,
      });
    }

    return results;
  }

  /**
   * Process all pending notifications (both email and push)
   */
  async processAllNotifications() {
    const emailResults = await this.processEmailNotifications();
    const pushResults = await this.processPushNotifications();

    return {
      email: emailResults,
      push: pushResults,
      total: {
        processed: emailResults.processed + pushResults.processed,
        sent: emailResults.sent + pushResults.sent,
        failed: emailResults.failed + pushResults.failed,
      },
    };
  }

  /**
   * Configure a delivery to fail for testing
   */
  simulateFailure(deliveryId, shouldFail = true) {
    this.failureSimulations.set(deliveryId, shouldFail);
  }

  /**
   * Check if a delivery should simulate failure
   */
  shouldSimulateFailure(deliveryId) {
    return this.failureSimulations.get(deliveryId) === true;
  }

  /**
   * Mark a delivery as failed
   */
  async markDeliveryFailed(deliveryId, errorMessage) {
    const nextAttempt = new Date();
    nextAttempt.setMinutes(nextAttempt.getMinutes() + 30); // 30 minute backoff

    await supabase
      .from("notification_deliveries")
      .update({
        status: "failed",
        error_message: errorMessage,
        next_attempt_at: nextAttempt.toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq("id", deliveryId);
  }

  /**
   * Get all sent emails (for verification in tests)
   */
  getSentEmails() {
    return this.sentEmails;
  }

  /**
   * Get all sent push notifications (for verification in tests)
   */
  getSentPushNotifications() {
    return this.sentPushNotifications;
  }

  /**
   * Get delivery attempts for a notification
   */
  getDeliveryAttempts(notificationId, channel) {
    return this.deliveryAttempts.get(`${notificationId}_${channel}`) || 0;
  }

  /**
   * Clear all stub data
   */
  reset() {
    this.sentEmails = [];
    this.sentPushNotifications = [];
    this.deliveryAttempts.clear();
    this.failureSimulations.clear();
  }

  /**
   * Verify no duplicate notifications were sent
   */
  verifyNoDuplicates() {
    // Check email duplicates
    const emailSet = new Set();
    for (const email of this.sentEmails) {
      const key = `${email.notificationId}_${email.userId}`;
      if (emailSet.has(key)) {
        return {
          hasDuplicates: true,
          type: "email",
          duplicateKey: key,
        };
      }
      emailSet.add(key);
    }

    // Check push duplicates
    const pushSet = new Set();
    for (const push of this.sentPushNotifications) {
      const key = `${push.notificationId}_${push.userId}`;
      if (pushSet.has(key)) {
        return {
          hasDuplicates: true,
          type: "push",
          duplicateKey: key,
        };
      }
      pushSet.add(key);
    }

    return { hasDuplicates: false };
  }

  /**
   * Get delivery statistics
   */
  getStats() {
    return {
      totalEmailsSent: this.sentEmails.length,
      totalPushSent: this.sentPushNotifications.length,
      uniqueNotifications: new Set([
        ...this.sentEmails.map((e) => e.notificationId),
        ...this.sentPushNotifications.map((p) => p.notificationId),
      ]).size,
      totalAttempts: Array.from(this.deliveryAttempts.values()).reduce(
        (a, b) => a + b,
        0
      ),
    };
  }
}
