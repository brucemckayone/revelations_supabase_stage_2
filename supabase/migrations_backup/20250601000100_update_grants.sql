-- Update permissions for our fixed functions

-- Grant for request_service_appointment with TEXT parameters 
GRANT ALL ON FUNCTION "public"."request_service_appointment"("p_service_id" "uuid", "p_requested_date" timestamp with time zone, "p_duration" integer, "p_method" text, "p_service_type" text, "p_notes" "text", "p_client_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."request_service_appointment"("p_service_id" "uuid", "p_requested_date" timestamp with time zone, "p_duration" integer, "p_method" text, "p_service_type" text, "p_notes" "text", "p_client_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."request_service_appointment"("p_service_id" "uuid", "p_requested_date" timestamp with time zone, "p_duration" integer, "p_method" text, "p_service_type" text, "p_notes" "text", "p_client_id" "uuid") TO "service_role";

-- Grant for respond_to_appointment_request with TEXT parameters
GRANT ALL ON FUNCTION "public"."respond_to_appointment_request"("p_appointment_id" "uuid", "p_action" "text", "p_alternative_time" timestamp with time zone, "p_provider_notes" "text", "p_base_url" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."respond_to_appointment_request"("p_appointment_id" "uuid", "p_action" "text", "p_alternative_time" timestamp with time zone, "p_provider_notes" "text", "p_base_url" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."respond_to_appointment_request"("p_appointment_id" "uuid", "p_action" "text", "p_alternative_time" timestamp with time zone, "p_provider_notes" "text", "p_base_url" "text") TO "service_role";

-- Grant for process_appointment_payment with TEXT parameters
GRANT ALL ON FUNCTION "public"."process_appointment_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_service_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "text", "p_service_type" "text", "p_notes" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."process_appointment_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_service_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "text", "p_service_type" "text", "p_notes" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_appointment_payment"("p_purchase_id" "uuid", "p_payment_intent_id" "text", "p_service_id" "uuid", "p_appointment_date" timestamp with time zone, "p_duration" integer, "p_method" "text", "p_service_type" "text", "p_notes" "text") TO "service_role"; 