drop function if exists "public"."get_user_appointments";
CREATE OR REPLACE FUNCTION "public"."get_user_appointments"(
    "p_user_id" "uuid" DEFAULT NULL::"uuid",
    "p_status" "text" DEFAULT NULL::"text",
    "p_limit" integer DEFAULT 100,
    "p_offset" integer DEFAULT 0
) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_user_id UUID;
    v_result JSONB;
BEGIN
    -- Default to current user
    v_user_id := COALESCE(p_user_id, auth.uid());
    
    -- Check permissions if trying to view another user's appointments
    IF v_user_id != auth.uid() AND NOT EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid() AND role = 'admin'
    ) THEN
        RETURN jsonb_build_object('error', 'Permission denied');
    END IF;
    
    -- Get appointments
    WITH user_appointments AS (
        SELECT
            ap.id AS appointment_id,
            p.id AS purchase_id,
            s.id AS service_id,
            pp.id AS post_id,
            pp.title AS service_title,
            pr.full_name AS provider_name,
            pr.avatar_url AS provider_avatar,
            p.owner_id AS provider_id,
            ap.appointment_date,
            ap.duration,
            ap.method,
            ap.service_type,
            ap.status,
            p.payment_status,
            p.amount,
            ap.appointment_date > CURRENT_TIMESTAMP AS is_future,
            ROW_NUMBER() OVER (
                ORDER BY 
                    CASE WHEN ap.appointment_date > CURRENT_TIMESTAMP THEN 0 ELSE 1 END,
                    ap.appointment_date
            ) AS row_num
        FROM
            public.appointment_purchases ap
        JOIN
            public.purchases p ON ap.purchase_id = p.id
        JOIN
            public.services s ON ap.service_id = s.id
        JOIN
            public.posts pp ON s.post_id = pp.id
        LEFT JOIN
            public.profiles pr ON p.owner_id = pr.id
        WHERE
            p.user_id = v_user_id
            AND (
                p_status IS NULL
                OR ap.status = p_status::appointment_status_enum
            )
    )
    SELECT jsonb_build_object(
        'appointments', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'appointment_id', appointment_id,
                    'purchase_id', purchase_id,
                    'service_id', service_id,
                    'service_title', service_title,
                    'provider_name', provider_name,
                    'provider_avatar', provider_avatar,
                    'provider_id', provider_id,
                    'appointment_date', appointment_date,
                    'duration', duration,
                    'method', method,
                    'service_type', service_type,
                    'status', status,
                    'payment_status', payment_status,
                    'amount', amount,
                    'is_future', is_future
                )
            )
            FROM user_appointments
            WHERE row_num > p_offset AND row_num <= (p_offset + p_limit)
        ),
        'count', (
            SELECT COUNT(*) FROM user_appointments
        ),
        'summary', (
            SELECT jsonb_build_object(
                'upcoming', COUNT(*) FILTER (WHERE is_future AND status = 'confirmed'),
                'pending', COUNT(*) FILTER (WHERE status IN ('pending_approval', 'pending_payment')),
                'past', COUNT(*) FILTER (WHERE NOT is_future AND status = 'confirmed'),
                'cancelled', COUNT(*) FILTER (WHERE status = 'cancelled')
            )
            FROM user_appointments
        )
    ) INTO v_result;
    
    RETURN v_result;
END;
$$;
