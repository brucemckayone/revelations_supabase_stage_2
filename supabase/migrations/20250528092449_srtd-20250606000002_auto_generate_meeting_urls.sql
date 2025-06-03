-- Generated with srtd from template: supabase/migrations-templates/20250606000002_auto_generate_meeting_urls.sql
-- You very likely **DO NOT** want to manually edit this generated file.

BEGIN;

-- ========================================
-- Auto Generate Meeting URLs for Online Services
-- ========================================
-- This migration adds automatic meeting URL generation for online and hybrid 
-- services when appointments are confirmed.

-- Drop existing trigger if it exists first
DROP TRIGGER IF EXISTS ensure_meeting_url_trigger ON public.appointment_purchases;

drop function if exists public.generate_meeting_url;
drop function if exists public.ensure_meeting_url_for_online_services;

-- Function to generate meeting URLs for online/hybrid services
CREATE OR REPLACE FUNCTION public.generate_meeting_url(
  p_appointment_id UUID
) RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_meeting_url TEXT;
BEGIN
  -- Generate a unique meeting URL
  v_meeting_url := 'https://local.revelations.com/meeting/private/' || gen_random_uuid();
  
  -- Update the appointment with the meeting URL
  UPDATE public.appointment_purchases
  SET meeting_url = v_meeting_url
  WHERE id = p_appointment_id;
  
  RETURN v_meeting_url;
END $$;

-- Function to ensure online/hybrid services have meeting URLs when confirmed
CREATE OR REPLACE FUNCTION public.ensure_meeting_url_for_online_services()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_service_type event_type_enum;
BEGIN
  -- Process for INSERT with confirmed status OR UPDATE changing to confirmed
  IF (TG_OP = 'INSERT' AND NEW.status::TEXT = 'confirmed') OR 
     (TG_OP = 'UPDATE' AND OLD.status::TEXT != 'confirmed' AND NEW.status::TEXT = 'confirmed') THEN
    
    -- Only process if meeting_url is not already set
    IF NEW.meeting_url IS NULL THEN
      
      -- Get service type
      SELECT s.type INTO v_service_type
      FROM public.services s
      WHERE s.id = NEW.service_id;
      
      -- Generate meeting URL for online and hybrid services
      IF v_service_type IN ('online'::event_type_enum, 'hybrid'::event_type_enum) THEN
        NEW.meeting_url := 'https://local.revelations.com/meeting/private/' || gen_random_uuid();
      END IF;
    END IF;
  END IF;
  
  RETURN NEW;
END $$;

-- ========================================
-- Create Trigger
-- ========================================

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS ensure_meeting_url_trigger ON public.appointment_purchases;

-- Create trigger to auto-generate meeting URLs
CREATE TRIGGER ensure_meeting_url_trigger
  BEFORE INSERT OR UPDATE OF status ON public.appointment_purchases
  FOR EACH ROW 
  EXECUTE FUNCTION public.ensure_meeting_url_for_online_services();

-- ========================================
-- Backfill existing confirmed appointments
-- ========================================

-- Update existing confirmed online/hybrid appointments that don't have meeting URLs
UPDATE public.appointment_purchases 
SET meeting_url = 'https://local.revelations.com/meeting/private/' || gen_random_uuid()
WHERE status = 'confirmed'
  AND meeting_url IS NULL
  AND service_id IN (
    SELECT s.id 
    FROM public.services s 
    WHERE s.type IN ('online', 'hybrid')
  );

-- ========================================
-- Comments
-- ========================================

COMMENT ON FUNCTION public.generate_meeting_url(UUID) IS 
'Generates a unique meeting URL for an appointment and updates the appointment record.';

COMMENT ON FUNCTION public.ensure_meeting_url_for_online_services() IS 
'Automatically generates meeting URLs for online and hybrid services when appointments are confirmed via INSERT or UPDATE operations.';

COMMENT ON TRIGGER ensure_meeting_url_trigger ON public.appointment_purchases IS 
'Automatically generates meeting URLs for online/hybrid services when status is confirmed on INSERT or UPDATE.'; 




COMMIT;

-- Last built: Never
-- Built with https://github.com/t1mmen/srtd
