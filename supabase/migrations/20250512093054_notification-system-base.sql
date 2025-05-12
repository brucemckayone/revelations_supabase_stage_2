
-- filename: supabase/migrations/20250512093054_notification-system-base.sql

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Notifications table
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('appointment', 'message', 'system', 'payment', 'reminder')),
  action_url TEXT,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  reference_id UUID,
  reference_type TEXT,
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.notifications IS 'Central repository for all user notifications across the system';

-- Notification deliveries table
CREATE TABLE public.notification_deliveries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
  channel TEXT NOT NULL CHECK (channel IN ('in_app', 'email', 'push', 'sms')),
  status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'sent', 'delivered', 'failed', 'cancelled')),
  external_id TEXT,
  error_message TEXT,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  next_attempt_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.notification_deliveries IS 'Tracks delivery status of notifications across different channels';

-- Notification preferences table
CREATE TABLE public.notification_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('appointment', 'message', 'system', 'payment', 'reminder')),
  in_app BOOLEAN NOT NULL DEFAULT TRUE,
  email BOOLEAN NOT NULL DEFAULT TRUE,
  push BOOLEAN NOT NULL DEFAULT TRUE,
  sms BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, type)
);

COMMENT ON TABLE public.notification_preferences IS 'Stores user-specific preferences for receiving notifications';

-- Email templates table
CREATE TABLE public.email_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  subject TEXT NOT NULL,
  html_content TEXT NOT NULL,
  text_content TEXT NOT NULL,
  variables JSONB NOT NULL DEFAULT '[]'::JSONB,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.email_templates IS 'Customizable templates for email notifications';

-- FCM tokens table
CREATE TABLE public.user_fcm_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  device_info JSONB DEFAULT '{}'::JSONB,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  last_used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, token)
);

COMMENT ON TABLE public.user_fcm_tokens IS 'Stores FCM tokens for push notifications';

-- Create indexes for performance
CREATE INDEX notifications_user_id_is_read_idx ON notifications(user_id, is_read);
CREATE INDEX notifications_user_id_type_idx ON notifications(user_id, type);
CREATE INDEX notifications_user_id_created_at_idx ON notifications(user_id, created_at DESC);
CREATE INDEX notification_deliveries_notification_id_idx ON notification_deliveries(notification_id);
CREATE INDEX notification_deliveries_status_idx ON notification_deliveries(status);
CREATE INDEX notification_deliveries_next_attempt_idx ON notification_deliveries(next_attempt_at) 
  WHERE status = 'pending' AND next_attempt_at IS NOT NULL;
CREATE INDEX notification_prefs_user_id_idx ON notification_preferences(user_id);
CREATE INDEX email_templates_name_idx ON email_templates(name);
CREATE INDEX user_fcm_tokens_user_id_idx ON user_fcm_tokens(user_id);
CREATE INDEX user_fcm_tokens_is_active_idx ON user_fcm_tokens(is_active);

-- Set up row-level security
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- RLS policies for notifications
CREATE POLICY notifications_select_policy ON notifications 
  FOR SELECT USING (user_id = auth.uid() OR EXISTS (
    SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY notifications_insert_policy ON notifications 
  FOR INSERT WITH CHECK (user_id = auth.uid() OR EXISTS (
    SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY notifications_update_policy ON notifications 
  FOR UPDATE USING (user_id = auth.uid() OR EXISTS (
    SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY notifications_delete_policy ON notifications 
  FOR DELETE USING (user_id = auth.uid() OR EXISTS (
    SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
  ));

-- RLS policies for notification deliveries
CREATE POLICY notification_deliveries_select_policy ON notification_deliveries 
  FOR SELECT USING (EXISTS (
    SELECT 1 FROM notifications 
    WHERE notifications.id = notification_id 
    AND (notifications.user_id = auth.uid() OR EXISTS (
      SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
    ))
  ));

-- RLS policies for notification preferences
CREATE POLICY notification_prefs_select_policy ON notification_preferences 
  FOR SELECT USING (user_id = auth.uid() OR EXISTS (
    SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY notification_prefs_insert_policy ON notification_preferences 
  FOR INSERT WITH CHECK (user_id = auth.uid() OR EXISTS (
    SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY notification_prefs_update_policy ON notification_preferences 
  FOR UPDATE USING (user_id = auth.uid() OR EXISTS (
    SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
  ));

-- RLS policies for email templates
CREATE POLICY email_templates_select_policy ON email_templates 
  FOR SELECT USING (TRUE); -- All users can view templates

CREATE POLICY email_templates_modify_policy ON email_templates 
  FOR ALL USING (EXISTS (
    SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
  ));

-- RLS policies for FCM tokens
CREATE POLICY user_fcm_tokens_select_policy ON user_fcm_tokens 
  FOR SELECT USING (user_id = auth.uid() OR EXISTS (
    SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY user_fcm_tokens_insert_policy ON user_fcm_tokens 
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY user_fcm_tokens_update_policy ON user_fcm_tokens 
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY user_fcm_tokens_delete_policy ON user_fcm_tokens 
  FOR DELETE USING (user_id = auth.uid());