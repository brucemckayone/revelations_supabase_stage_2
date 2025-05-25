-- Drop the duplicate process_appointment_payment function
-- This removes the version that takes TEXT parameters instead of proper ENUM types
DROP FUNCTION IF EXISTS "public"."process_appointment_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_service_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "text", "p_service_type" "text", "p_notes" "text");

-- Keep the version that uses proper ENUM types:
-- process_appointment_payment(p_purchase_id uuid, p_payment_intent_id text, p_service_id uuid, 
--                            p_appointment_date timestamp with time zone, p_duration integer, 
--                            p_method appointment_method_enum, p_service_type appointment_type_enum, p_notes text)

COMMENT ON FUNCTION "public"."process_appointment_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_service_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "public"."appointment_method_enum", "p_service_type" "public"."appointment_type_enum", "p_notes" "text") IS 'Processes an appointment payment, ensuring the appointment_purchase record exists and has correct status. Uses proper ENUM types.'; 

