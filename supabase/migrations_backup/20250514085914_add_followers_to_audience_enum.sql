-- Add 'followers' value to notification_audience_type enum
ALTER TYPE public.notification_audience_type ADD VALUE IF NOT EXISTS 'followers'; 