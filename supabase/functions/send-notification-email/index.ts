import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  SESv2Client,
  SendEmailCommand,
} from "https://esm.sh/@aws-sdk/client-sesv2";

// Initialize Supabase client
const supabaseUrl = Deno.env.get("SUPABASE_URL") as string;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") as string;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Initialize SES client
const ses = new SESv2Client({
  region: Deno.env.get("AWS_REGION") || "us-east-1",
  credentials: {
    accessKeyId: Deno.env.get("AWS_ACCESS_KEY_ID") as string,
    secretAccessKey: Deno.env.get("AWS_SECRET_ACCESS_KEY") as string,
  },
});

serve(async (req) => {
  try {
    // This function should be triggered by a cron job or webhook
    // to process pending email notifications

    // Get pending email notifications (limit to 10 at a time to avoid timeout)
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
      .eq("channel", "email")
      .eq("status", "pending")
      .is("error_message", null)
      .lt("attempt_count", 3)
      .order("created_at", { ascending: true })
      .limit(10);

    if (deliveryError) {
      throw new Error(
        `Error fetching pending deliveries: ${deliveryError.message}`
      );
    }

    if (!pendingDeliveries || pendingDeliveries.length === 0) {
      return new Response(
        JSON.stringify({ message: "No pending email notifications" }),
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

          // Get user email
          const { data: userData, error: userError } = await supabase
            .from("auth.users")
            .select("email")
            .eq("id", delivery.notifications.user_id)
            .single();

          if (userError || !userData) {
            throw new Error(
              `User not found: ${userError?.message || "Unknown error"}`
            );
          }

          // Get appropriate email template
          const { data: template, error: templateError } = await supabase
            .from("email_templates")
            .select("*")
            .eq("name", `${delivery.notifications.type}_notification`)
            .eq("is_active", true)
            .single();

          if (templateError) {
            throw new Error(`Template not found: ${templateError.message}`);
          }

          // Prepare email content - replace variables in template
          let htmlContent = template.html_content;
          let textContent = template.text_content;
          let subject = template.subject;

          // Replace basic variables
          const replacements = {
            "{{title}}": delivery.notifications.title,
            "{{content}}": delivery.notifications.content,
            "{{action_url}}": delivery.notifications.action_url || "",
            // Add more dynamic replacements as needed
          };

          for (const [placeholder, value] of Object.entries(replacements)) {
            htmlContent = htmlContent.replace(
              new RegExp(placeholder, "g"),
              value
            );
            textContent = textContent.replace(
              new RegExp(placeholder, "g"),
              value
            );
            subject = subject.replace(new RegExp(placeholder, "g"), value);
          }

          // Send email using AWS SES
          const sendEmailParams = {
            Content: {
              Simple: {
                Body: {
                  Html: {
                    Data: htmlContent,
                    Charset: "UTF-8",
                  },
                  Text: {
                    Data: textContent,
                    Charset: "UTF-8",
                  },
                },
                Subject: {
                  Data: subject,
                  Charset: "UTF-8",
                },
              },
            },
            Destination: {
              ToAddresses: [userData.email],
            },
            FromEmailAddress:
              Deno.env.get("FROM_EMAIL") || "notifications@example.com",
          };

          const command = new SendEmailCommand(sendEmailParams);
          const response = await ses.send(command);

          // Update delivery status to sent
          await supabase
            .from("notification_deliveries")
            .update({
              status: "sent",
              external_id: response.MessageId,
              updated_at: new Date().toISOString(),
            })
            .eq("id", delivery.id);

          return {
            id: delivery.id,
            notification_id: delivery.notification_id,
            status: "sent",
            message_id: response.MessageId,
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
