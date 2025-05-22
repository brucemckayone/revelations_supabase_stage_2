
-- Update any appointment_purchases statuses that may need to be consistent 
-- This assumes that 'pending_payment' is an acceptable status in appointment_purchases but not in purchases
-- We don't change this since it's allowed by the appointment_purchases constraint 