import { NextRequest, NextResponse } from "next/server";
import Stripe from "stripe";
import stripe from "@/lib/stripe/stripe";
import { cookies } from "next/headers";
import { headers } from "next/headers";
import { createAdminClient } from "@/lib/supabase/server";

export async function POST(req: NextRequest) {
  const body = await req.text();
  const headersList = headers();
  const signature = (await headersList).get("stripe-signature") || "";

  let event: Stripe.Event;

  try {
    // Verify the webhook signature
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET || ""
    );
  } catch (err: any) {
    console.error(`Webhook signature verification failed: ${err.message}`);
    return NextResponse.json({ error: err.message }, { status: 400 });
  }

  const supabase = createAdminClient(await cookies());
  // Store event in database for idempotency and auditing
  const { data: existingEvent, error: lookupError } = await supabase
    .from("stripe_webhook_events")
    .select("id, processed")
    .eq("id", event.id)
    .maybeSingle();

  if (lookupError) {
    console.error(`Error looking up webhook event: ${lookupError.message}`);
  }

  if (existingEvent) {
    // Event already processed or in progress
    if (existingEvent.processed) {
      return NextResponse.json({
        success: true,
        message: "Event already processed",
      });
    }
    // Event is being processed, avoid duplicate processing
    return NextResponse.json({
      success: true,
      message: "Event already being processed",
    });
  }

  // Get object ID and type safely
  const objectId =
    typeof event.data.object === "object" && event.data.object
      ? "id" in event.data.object
        ? event.data.object.id
        : undefined
      : undefined;

  const objectType =
    typeof event.data.object === "object" && event.data.object
      ? "object" in event.data.object
        ? event.data.object.object
        : undefined
      : undefined;

  // Insert the new event
  const { error: insertError } = await supabase
    .from("stripe_webhook_events")
    .insert({
      id: event.id,
      object_id: objectId || "",
      object_type: objectType || "",
      type: event.type,
      data: JSON.parse(JSON.stringify(event.data)),
      created_at: new Date().toISOString(),
      processed: false,
    });

  if (insertError) {
    console.error(`Error storing webhook event: ${insertError.message}`);
    return NextResponse.json(
      { error: "Error storing webhook event" },
      { status: 500 }
    );
  }

  try {
    switch (event.type) {
      case "payment_intent.succeeded":
        await handlePaymentIntentSucceeded(
          event.data.object as Stripe.PaymentIntent
        );
        break;

      case "payment_intent.created":
        // Just log the event, no specific handling needed yet
        console.log(
          "Payment intent created:",
          (event.data.object as Stripe.PaymentIntent).id
        );
        break;

      case "checkout.session.completed":
        await handleCheckoutSessionCompleted(
          event.data.object as Stripe.Checkout.Session
        );
        break;

      case "invoice.paid":
        await handleInvoicePaid(event.data.object as Stripe.Invoice);
        break;

      case "invoice.payment_failed":
        await handleInvoicePaymentFailed(event.data.object as Stripe.Invoice);
        break;

      case "customer.subscription.created":
      case "customer.subscription.updated":
        await handleSubscriptionUpdated(
          event.data.object as Stripe.Subscription
        );
        break;

      case "customer.subscription.deleted":
        await handleSubscriptionDeleted(
          event.data.object as Stripe.Subscription
        );
        break;

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    // Mark event as processed
    const { error: updateError } = await supabase
      .from("stripe_webhook_events")
      .update({ processed: true, processed_at: new Date().toISOString() })
      .eq("id", event.id);

    if (updateError) {
      console.error(`Error updating webhook event: ${updateError.message}`);
    }

    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error(`Error processing webhook: ${error.message}`, error);

    // Update record with error information
    const { error: updateError } = await supabase
      .from("stripe_webhook_events")
      .update({
        processing_error: error.message,
        processed: false,
        updated_at: new Date().toISOString(),
      })
      .eq("id", event.id);

    if (updateError) {
      console.error(`Error updating webhook event: ${updateError.message}`);
    }

    return NextResponse.json(
      { error: `Error processing webhook: ${error.message}` },
      { status: 500 }
    );
  }
}

/**
 * Handle successful payment intent completion
 */
async function handlePaymentIntentSucceeded(
  paymentIntent: Stripe.PaymentIntent
) {
  // Add debug logging
  console.log("Webhook received payment intent ID:", paymentIntent.id);
  console.log(
    "Webhook payment intent details:",
    JSON.stringify(
      {
        id: paymentIntent.id,
        object: paymentIntent.object,
        status: paymentIntent.status,
        metadata: paymentIntent.metadata,
      },
      null,
      2
    )
  );

  const metadata = paymentIntent.metadata;
  const purchaseType = metadata.purchase_type;

  if (!purchaseType) {
    throw new Error("Missing purchase_type in payment intent metadata");
  }

  // Call the appropriate database function using RPC
  switch (purchaseType) {
    case "content":
      return processContentPurchase(paymentIntent);
    case "event":
      return processEventBooking(paymentIntent);
    case "appointment":
      return processAppointmentBooking(paymentIntent);
    default:
      throw new Error(`Unsupported purchase type: ${purchaseType}`);
  }
}

/**
 * Process a content purchase
 */
async function processContentPurchase(paymentIntent: Stripe.PaymentIntent) {
  const { metadata } = paymentIntent;
  const supabase = createAdminClient(await cookies());

  // Update the purchase record
  const { data: purchaseData, error: purchaseError } = await supabase
    .from("purchases")
    .update({
      payment_status: "completed",
      completed_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      // We already have stripe_payment_intent_id, no need to update it again
    })
    .eq("stripe_payment_intent_id", paymentIntent.id)
    .select("id")
    .single();

  if (purchaseError) {
    console.error(`Error updating purchase record: ${purchaseError.message}`);
    throw new Error(`Error updating purchase record: ${purchaseError.message}`);
  }
  // Create content purchase record
  const { data: contentPurchaseData, error: contentPurchaseError } =
    await supabase.from("content_purchases").insert({
      content_id: metadata.content_id,
      purchase_id: purchaseData.id,
      // Set expiry if needed
      // access_expires_at: expiryDate ? new Date(expiryDate).toISOString() : null,
    });

  if (contentPurchaseError) {
    console.error(
      `Error creating content purchase record: ${contentPurchaseError.message}`
    );
    throw new Error(
      `Error creating content purchase record: ${contentPurchaseError.message}`
    );
  }
}

/**
 * Process an event booking
 */
async function processEventBooking(paymentIntent: Stripe.PaymentIntent) {
  const { metadata } = paymentIntent;
  const supabase = createAdminClient(await cookies());

  // First, find the purchase ID using the payment intent
  const { data: purchaseData, error: purchaseError } = await supabase
    .from("purchases")
    .select("id")
    .eq("stripe_payment_intent_id", paymentIntent.id)
    .single();

  if (purchaseError || !purchaseData) {
    console.error(
      `Purchase not found for payment intent: ${paymentIntent.id}`,
      purchaseError
    );
    throw new Error("Purchase not found");
  }

  // Call our database function to process the event booking
  const { data: updateData, error: updateError } = await supabase.rpc(
    "process_event_booking_payment",
    {
      p_purchase_id: purchaseData.id,
      p_payment_intent_id: paymentIntent.id,
      p_ticket_id: metadata.ticket_id,
      p_date_id: metadata.date_id,
      p_attendees: parseInt(metadata.attendees || "1"),
      p_is_virtual: metadata.is_virtual === "true",
    }
  );

  if (updateError) {
    console.error(`Error processing event booking: ${updateError.message}`);
    throw new Error(`Error processing event booking: ${updateError.message}`);
  }

  return updateData;
}

/**
 * Process a service appointment booking
 */
async function processAppointmentBooking(paymentIntent: Stripe.PaymentIntent) {
  const { metadata } = paymentIntent;
  const supabase = createAdminClient(await cookies());

  // Add debug logging
  console.log("Processing appointment booking:", {
    paymentIntentId: paymentIntent.id,
    metadata: metadata,
  });

  // First, find the purchase ID using the payment intent
  const { data: purchaseData, error: purchaseError } = await supabase
    .from("purchases")
    .select("id")
    .eq("stripe_payment_intent_id", paymentIntent.id)
    .single();

  if (purchaseError || !purchaseData) {
    // If not found by payment intent ID, try to use the purchase_id from metadata
    if (metadata.purchase_id) {
      console.log(
        "Purchase not found by payment intent, trying metadata purchase_id:",
        metadata.purchase_id
      );

      const { data: purchaseCheck, error: checkError } = await supabase
        .from("purchases")
        .select("id")
        .eq("id", metadata.purchase_id)
        .single();

      if (checkError || !purchaseCheck) {
        console.error(
          `Purchase not found for payment intent: ${paymentIntent.id} or purchase_id: ${metadata.purchase_id}`,
          { purchaseError, checkError }
        );
        throw new Error("Purchase not found");
      }

      // Call the simplified database function to process the appointment payment
      const { data: confirmData, error: confirmError } = await supabase.rpc(
        "process_appointment_payment_confirmation",
        {
          p_purchase_id: metadata.purchase_id,
          p_payment_intent_id: paymentIntent.id,
        }
      );

      if (confirmError) {
        console.error(
          `Error confirming appointment payment: ${confirmError.message}`,
          {
            purchaseId: metadata.purchase_id,
            paymentIntentId: paymentIntent.id,
            error: confirmError,
          }
        );
        throw new Error(
          `Error confirming appointment payment: ${confirmError.message}`
        );
      }

      console.log("Appointment payment confirmed successfully:", {
        purchaseId: metadata.purchase_id,
        result: confirmData,
      });

      return confirmData;
    } else {
      console.error(
        `Purchase not found for payment intent: ${paymentIntent.id} and no purchase_id in metadata`,
        { purchaseError, metadata }
      );
      throw new Error("Purchase not found");
    }
  }

  console.log("Found purchase by payment intent:", purchaseData.id);

  // Call the simplified database function to process the appointment payment
  const { data: confirmData, error: confirmError } = await supabase.rpc(
    "process_appointment_payment_confirmation",
    {
      p_purchase_id: purchaseData.id,
      p_payment_intent_id: paymentIntent.id,
    }
  );

  if (confirmError) {
    console.error(
      `Error confirming appointment payment: ${confirmError.message}`,
      {
        purchaseId: purchaseData.id,
        paymentIntentId: paymentIntent.id,
        error: confirmError,
      }
    );
    throw new Error(
      `Error confirming appointment payment: ${confirmError.message}`
    );
  }

  console.log("Appointment payment confirmed successfully:", {
    purchaseId: purchaseData.id,
    result: confirmData,
  });

  return confirmData;
}

/**
 * Handle completed checkout session
 */
async function handleCheckoutSessionCompleted(
  session: Stripe.Checkout.Session
) {
  // For checkout sessions, we handle based on the mode
  if (session.mode === "subscription") {
    // This will be handled by the subscription.created event
    console.log("Subscription created via checkout session", session.id);
  } else if (session.mode === "payment") {
    // One-time payment via Checkout
    // The payment_intent.succeeded event will handle this
    console.log("Payment completed via checkout session", session.id);
  }
}

/**
 * Handle successful subscription invoice payment
 */
async function handleInvoicePaid(invoice: Stripe.Invoice) {
  if (!invoice.subscription) return;

  // Fetch the subscription to get metadata
  const subscription = await stripe.subscriptions.retrieve(
    invoice.subscription as string
  );
  const supabase = createAdminClient(await cookies());
  // Update the subscription status in the database
  // await supabase.rpc('process_invoice_paid', {
  //   event_data: JSON.stringify(invoice),
  // });
}

/**
 * Handle failed subscription invoice payment
 */
async function handleInvoicePaymentFailed(invoice: Stripe.Invoice) {
  if (!invoice.subscription) return;
  const supabase = createAdminClient(await cookies());
  // Update the subscription status in the database
  // await supabase.rpc('process_invoice_payment_failed', {
  //   invoice_id: invoice.id,
  //   subscription_id: invoice.subscription as string,
  //   invoice_data: invoice,
  // });
}

/**
 * Handle subscription created or updated
 */
async function handleSubscriptionUpdated(subscription: Stripe.Subscription) {
  const metadata = subscription.metadata;

  // Ensure we have purchase_type
  if (!metadata.purchase_type || metadata.purchase_type !== "subscription") {
    console.warn("Subscription missing proper metadata", subscription.id);
    return;
  }

  let purchaseId;
  const supabase = createAdminClient(await cookies());
  // Check if we already have a purchase record
  const { data: purchaseData } = await supabase
    .from("purchases")
    .select("id")
    .eq("stripe_subscription_id", subscription.id)
    .single();

  if (purchaseData) {
    purchaseId = purchaseData.id;

    // Update existing purchase record
    await supabase
      .from("purchases")
      .update({
        payment_status: mapSubscriptionStatus(subscription.status),
        updated_at: new Date().toISOString(),
      })
      .eq("id", purchaseId);
  } else {
    // Create new purchase record if none exists
    const { data: newPurchase, error } = await supabase
      .from("purchases")
      .insert({
        user_id: metadata.user_id,
        owner_id: metadata.owner_id,
        amount: subscription.items.data[0]?.price.unit_amount
          ? subscription.items.data[0].price.unit_amount / 100
          : 0,
        payment_processor: "stripe",
        payment_method: "card",
        payment_status: mapSubscriptionStatus(subscription.status),
        purchase_type: "subscription",
        stripe_subscription_id: subscription.id,
        metadata: metadata,
      })
      .select()
      .single();

    if (error) {
      throw new Error(`Error creating purchase record: ${error.message}`);
    }

    purchaseId = newPurchase.id;
  }

  // Check if we have a subscription record
  const { data: subscriptionData } = await supabase
    .from("subscriptions")
    .select("id")
    .eq("purchase_id", purchaseId)
    .single();

  if (subscriptionData) {
    // Update existing subscription
    await supabase
      .from("subscriptions")
      .update({
        status: mapSubscriptionStatus(subscription.status),
        current_period_start: new Date(
          subscription.current_period_start * 1000
        ).toISOString(),
        current_period_end: new Date(
          subscription.current_period_end * 1000
        ).toISOString(),
        cancel_at_period_end: subscription.cancel_at_period_end,
        updated_at: new Date().toISOString(),
      })
      .eq("id", subscriptionData.id);
  } else {
    // Create new subscription record
    // await supabase
    //   .from('subscriptions')
    //   .insert({
    //     purchase_id: purchaseId,
    //     tier: metadata.tier,
    //     status: mapSubscriptionStatus(subscription.status),
    //     current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
    //     current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
    //     cancel_at_period_end: subscription.cancel_at_period_end,
    //   });
  }
}

/**
 * Handle subscription deleted/canceled
 */
async function handleSubscriptionDeleted(subscription: Stripe.Subscription) {
  // Update subscription status
  const supabase = createAdminClient(await cookies());

  await supabase
    .from("subscriptions")
    .update({
      status: "canceled",
      ended_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq("stripe_subscription_id", subscription.id);

  // Also update related purchase
  await supabase
    .from("purchases")
    .update({
      payment_status: "canceled",
      updated_at: new Date().toISOString(),
    })
    .eq("stripe_subscription_id", subscription.id);
}

/**
 * Map Stripe subscription status to our database payment_status enum
 * Database only accepts: "completed" | "pending" | "refunded" | "failed"
 */
function mapSubscriptionStatus(
  stripeStatus: string
): "completed" | "pending" | "refunded" | "failed" {
  switch (stripeStatus) {
    case "trialing":
    case "active":
      return "completed"; // Active subscriptions are considered completed payments
    case "incomplete":
    case "incomplete_expired":
    case "unpaid":
      return "failed";
    case "past_due":
      return "pending"; // Past due could still be recovered
    case "canceled":
      return "refunded"; // Canceled subscriptions can be considered refunded
    default:
      return "pending";
  }
}
