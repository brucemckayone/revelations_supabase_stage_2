


CREATE TABLE IF NOT EXISTS "public"."purchases" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "owner_id" "uuid" NOT NULL,
    "stripe_payment_intent_id" "text",
    "stripe_invoice_id" "text",
    "stripe_subscription_id" "text",
    "stripe_customer_id" "text",
    "amount" numeric(10,2) NOT NULL,
    "currency" "text" DEFAULT 'GBP'::"text" NOT NULL,
    "payment_status" "public"."purchase_payment_status_enum" NOT NULL,
    "post_id" "uuid",
    "content_id" "uuid",
    "service_id" "uuid",
    "event_id" "uuid",
    "purchase_type" "public"."purchase_type_enum" NOT NULL,
    "purchase_date" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "start_date" timestamp with time zone,
    "end_date" timestamp with time zone,
    "quantity" integer DEFAULT 1 NOT NULL,
    "metadata" "jsonb",
    "completed_at" timestamp with time zone,
    "ended_at" timestamp with time zone,
    "refunded_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "check_only_one_item_type" CHECK (((((("content_id" IS NOT NULL))::integer + (("service_id" IS NOT NULL))::integer) + (("event_id" IS NOT NULL))::integer) <= 1))
);
