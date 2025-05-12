import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { initializeApp } from "https://esm.sh/firebase-admin/app";
import { getMessaging } from "https://esm.sh/firebase-admin/messaging";

// Initialize Supabase client
const supabaseUrl = Deno.env.get("SUPABASE_URL") as string;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") as string;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Initialize Firebase Admin
const firebaseConfig = {
  credential: {
    projectId: Deno.env.get("FIREBASE_PROJECT_ID"),
    clientEmail: Deno.env.get("FIREBASE_CLIENT_EMAIL"),
    privateKey: Deno.env.get("FIREBASE_PRIVATE_KEY")?.replace(/\\n/g, "\n"),
  },
};

const app = initializeApp(firebaseConfig);
const messaging = getMessaging(app);

serve(async (req) => {
  try {
    // This function should be triggered by a cron job or webhook
    // to process pending push notifications

    // Get pending push notifications (limit to 50 at a time)
    const { data: pendingDeliveries, error: deliveryError } = await supabase
      .from("notification_deliveries")
      .select(
        `
        id,
        notification_id,
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
      .is("error_message", null)
      .lt("attempt_count", 3)
      .order("created_at", { ascending: true })
      .limit(50);

    if (deliveryError) {
      throw new Error(
        `Error fetching pending deliveries: ${deliveryError.message}`
      );
    }

    if (!pendingDeliveries || pendingDeliveries.length === 0) {
      return new Response(
        JSON.stringify({ message: "No pending push notifications" }),
        {
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    // Process each notification
    const results = await Promise.all(
      pendingDeliveries.map(async (delivery) => {
        try {
          // Update status to processing
          await supabase
            .from("notification_deliveries")
            .update({
              status: "processing",
              attempt_count: delivery.attempt_count + 1,
              updated_at: new Date().toISOString(),
            })
            .eq("id", delivery.id);

          // Get user FCM tokens
          const { data: tokens, error: tokensError } = await supabase
            .from("user_fcm_tokens")
            .select("token")
            .eq("user_id", delivery.notifications.user_id)
            .eq("is_active", true);

          if (tokensError) {
            throw new Error(
              `Error fetching user tokens: ${tokensError.message}`
            );
          }

          if (!tokens || tokens.length === 0) {
            throw new Error("No active FCM tokens found for user");
          }

          // Prepare notification payload
          const notificationPayload = {
            notification: {
              title: delivery.notifications.title,
              body: delivery.notifications.content,
            },
            data: {
              notificationId: delivery.notifications.id,
              type: delivery.notifications.type,
              actionUrl: delivery.notifications.action_url || "",
              // Add any other data needed by the client
              metadata: JSON.stringify(delivery.notifications.metadata),
            },
          };

          // Send to all user devices
          const sendPromises = tokens.map(async (tokenObj) => {
            try {
              const response = await messaging.send({
                token: tokenObj.token,
                ...notificationPayload,
              });

              return {
                token: tokenObj.token,
                status: "sent",
                messageId: response,
              };
            } catch (error) {
              if (
                error.code === "messaging/invalid-registration-token" ||
                error.code === "messaging/registration-token-not-registered"
              ) {
                // Deactivate invalid tokens
                await supabase
                  .from("user_fcm_tokens")
                  .update({
                    is_active: false,
                    updated_at: new Date().toISOString(),
                  })
                  .eq("token", tokenObj.token);
              }

              return {
                token: tokenObj.token,
                status: "failed",
                error: error.message,
              };
            }
          });

          const sendResults = await Promise.all(sendPromises);

          // Check if at least one token succeeded
          const anySuccess = sendResults.some(
            (result) => result.status === "sent"
          );

          // Update delivery status
          await supabase
            .from("notification_deliveries")
            .update({
              status: anySuccess ? "sent" : "failed",
              error_message: anySuccess ? null : "All tokens failed",
              external_id:
                sendResults.find((r) => r.status === "sent")?.messageId || null,
              updated_at: new Date().toISOString(),
            })
            .eq("id", delivery.id);

          return {
            id: delivery.id,
            notification_id: delivery.notification_id,
            status: anySuccess ? "sent" : "failed",
            results: sendResults,
          };
        } catch (error) {
          // Update delivery status to failed
          await supabase
            .from("notification_deliveries")
            .update({
              status: "failed",
              error_message: error.message,
              next_attempt_at: new Date(
                Date.now() + 30 * 60 * 1000
              ).toISOString(), // Retry in 30 minutes
              updated_at: new Date().toISOString(),
            })
            .eq("id", delivery.id);

          return {
            id: delivery.id,
            notification_id: delivery.notification_id,
            status: "failed",
            error: error.message,
          };
        }
      })
    );

    return new Response(JSON.stringify({ results }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
