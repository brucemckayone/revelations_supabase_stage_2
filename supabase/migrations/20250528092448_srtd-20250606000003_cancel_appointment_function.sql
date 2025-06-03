-- Generated with srtd from template: supabase/migrations-templates/20250606000003_cancel_appointment_function.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- ========================================
-- Cancel Appointment Request Function
-- ========================================
-- This migration adds a function to cancel appointments with appropriate
-- logic based on payment status (refund vs simple cancellation)

-- Function to cancel an appointment with payment status awareness
CREATE OR REPLACE FUNCTION public.cancel_appointment_request(
  p_appointment_id UUID,
  p_reason TEXT DEFAULT NULL,
  p_minimum_hours_before INTEGER DEFAULT 24
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appointment RECORD;
  v_user_id UUID;
  v_can_cancel BOOLEAN := false;
  v_needs_refund BOOLEAN := false;
  v_hours_until_appointment NUMERIC;
  v_is_provider BOOLEAN := false;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required'
      USING HINT = 'User must be authenticated to cancel appointments';
  END IF;

  -- Validate reason is provided
  IF p_reason IS NULL OR TRIM(p_reason) = '' THEN
    RAISE EXCEPTION 'Cancellation reason is required'
      USING HINT = 'Please provide a reason for cancelling the appointment';
  END IF;

  -- Get appointment details with payment info
  SELECT 
    ap.*,
    p.title as service_name,
    pu.user_id as client_id,
    pu.owner_id as provider_id,
    pu.amount,
    pu.payment_status,
    COALESCE(uc.full_name, 'Unknown Client') as client_name,
    COALESCE(uo.full_name, 'Unknown Provider') as provider_name
  INTO v_appointment
  FROM public.appointment_purchases ap
  JOIN public.services s ON ap.service_id = s.id
  JOIN public.posts p ON s.post_id = p.id
  JOIN public.purchases pu ON ap.purchase_id = pu.id
  JOIN public.profiles uc ON pu.user_id = uc.id
  JOIN public.profiles uo ON pu.owner_id = uo.id
  WHERE ap.id = p_appointment_id;

  -- Check if appointment exists
  IF v_appointment IS NULL THEN
    RAISE EXCEPTION 'Appointment not found'
      USING HINT = 'The specified appointment does not exist or has been deleted';
  END IF;

  -- Check if user has permission to cancel (client or provider)
  IF v_user_id NOT IN (v_appointment.client_id, v_appointment.provider_id) THEN
    RAISE EXCEPTION 'You do not have permission to cancel this appointment'
      USING HINT = 'Only the client or provider can cancel an appointment';
  END IF;

  -- Determine if user is the provider
  v_is_provider := (v_user_id = v_appointment.provider_id);

  -- Calculate hours until appointment
  v_hours_until_appointment := EXTRACT(EPOCH FROM (v_appointment.appointment_date - now())) / 3600;

  -- Check if appointment can be cancelled based on status
  CASE v_appointment.status::TEXT
    WHEN 'pending_approval', 'pending_payment', 'pending_auto_payment' THEN
      v_can_cancel := true;
      v_needs_refund := false;
    WHEN 'confirmed' THEN
      -- Check time restriction for clients (providers can always cancel but with different refund rules)
      IF NOT v_is_provider AND v_hours_until_appointment < p_minimum_hours_before THEN
        RAISE EXCEPTION 'Cannot cancel appointment less than % hours before the scheduled time. Current time until appointment: % hours. Please contact the provider directly for emergency cancellations. Hours required: % Hours available: %',
          p_minimum_hours_before,
          ROUND(v_hours_until_appointment, 1),
          p_minimum_hours_before,
          ROUND(v_hours_until_appointment, 1)
          USING HINT = 'Cancellation policy requires minimum notice period';
      END IF;
      
      
      v_can_cancel := true;
      
      -- Refund logic based on timing and who is cancelling
      IF v_appointment.payment_status = 'completed' THEN
        IF v_is_provider THEN
          -- Provider cancelling - always offer full refund
          v_needs_refund := true;
        ELSE
          -- Client cancelling - refund based on timing
          IF v_hours_until_appointment >= p_minimum_hours_before THEN
            v_needs_refund := true;
          ELSE
            -- This case shouldn't happen due to the check above, but just in case
            v_needs_refund := false;
          END IF;
        END IF;
      ELSE
        v_needs_refund := false;
      END IF;
      
    WHEN 'cancelled', 'completed', 'no_show' THEN
      RAISE EXCEPTION 'This appointment cannot be cancelled (status: %)', v_appointment.status::TEXT
        USING HINT = 'Appointment is already completed or cancelled';
    ELSE
      v_can_cancel := true;
      v_needs_refund := false;
  END CASE;


  -- Perform the cancellation
  IF v_can_cancel THEN
    -- Update appointment status to cancelled (triggers will handle messaging)
    UPDATE public.appointment_purchases
    SET 
      status = 'cancelled'::appointment_status_enum,
      updated_at = now(),
      metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
        'cancellation_reason', TRIM(p_reason),
        'cancelled_at', now(),
        'cancelled_by', v_user_id,
        'cancelled_by_role', CASE WHEN v_is_provider THEN 'provider' ELSE 'client' END,
        'needs_refund', v_needs_refund,
        'hours_before_appointment', v_hours_until_appointment,
        'minimum_hours_policy', p_minimum_hours_before
      )
    WHERE id = p_appointment_id;

    -- Return success response
    RETURN jsonb_build_object(
      'appointment_id', p_appointment_id,
      'status', 'cancelled',
      'needs_refund', v_needs_refund,
      'refund_amount', CASE WHEN v_needs_refund THEN v_appointment.amount ELSE 0 END,
      'hours_until_appointment', v_hours_until_appointment,
      'cancelled_by_role', CASE WHEN v_is_provider THEN 'provider' ELSE 'client' END,
      'message', CASE 
        WHEN v_needs_refund THEN 'Appointment cancelled. Refund will be processed within 3-5 business days.'
        WHEN v_is_provider THEN 'Appointment cancelled by provider.'
        ELSE 'Appointment cancelled successfully.'
      END
    );
  ELSE
    RAISE EXCEPTION 'This appointment cannot be cancelled at this time'
      USING HINT = 'Appointment status or timing restrictions prevent cancellation';
  END IF;
END $$;

-- ========================================
-- Comments
-- ========================================

COMMENT ON FUNCTION public.cancel_appointment_request(UUID, TEXT, INTEGER) IS 
'Cancels an appointment with appropriate logic based on payment status. Handles refunds for paid appointments and simple cancellation for unpaid ones. Creates chat notifications and updates appointment status.'; 

COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
