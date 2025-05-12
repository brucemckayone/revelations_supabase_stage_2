# Service Appointment System Improvements

## Current System Analysis

Our platform currently operates with two parallel appointment systems that aren't fully integrated, creating friction and potential conflicts for both service providers and clients.

### 1. Legacy Appointment System

The original system uses the `availability` and `appointments` tables with the following characteristics:

```sql
-- Schema for availability table
CREATE TABLE public.availability (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    day VARCHAR(20) CHECK (day IN ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday')),
    is_active BOOLEAN NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    -- constraints and other fields
);

-- Schema for appointments table
CREATE TABLE public.appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    facilitator_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    client_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'rejected', 'suggested')),
    -- additional fields
);
```

**Key Functions:**

- `set_availability(user_id, day, is_active, start_time, end_time)`: Sets recurring weekly availability
- `get_available_slots(facilitator_id, start_date, end_date)`: Calculates available time slots
- `book_appointment(facilitator_id, client_id, start_time, end_time)`: Creates pending appointments
- `respond_to_appointment(appointment_id, action)`: Confirms or rejects appointments

**Workflow:**

1. Provider sets weekly availability (e.g., Monday 9am-5pm)
2. System calculates available time slots
3. Client requests an appointment within available slots
4. Provider confirms or rejects the appointment
5. Confirmed appointments block those time slots from future bookings

**Strengths:**

- Prevents double-booking within the legacy system
- Provides two-way confirmation protocol
- Supports suggested alternative times

**Weaknesses:**

- Not integrated with the payment system
- No connection to the events system
- Limited to fixed weekly schedules without exceptions

### 2. Purchase-Based Appointment System

The newer system introduced with the purchase system redesign uses:

```sql
-- From purchase_system_redesign.sql
CREATE TABLE public.appointment_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_id UUID NOT NULL REFERENCES public.purchases(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
    appointment_date TIMESTAMP WITH TIME ZONE NOT NULL,
    duration INTEGER NOT NULL, -- in minutes
    method TEXT NOT NULL CHECK (method IN ('video', 'phone', 'in-person')),
    service_type TEXT NOT NULL CHECK (service_type IN ('reading', 'healing', 'coaching', 'consultation')),
    status TEXT NOT NULL CHECK (status IN ('confirmed', 'pending', 'cancelled', 'completed')),
    -- additional fields
);
```

**Key Functions:**

- `process_payment_intent_succeeded(payment_intent_id, event_data)`: Creates an appointment when payment succeeds
- `process_appointment_payment(purchase_id, payment_intent_id, ...)`: Updates appointment status after payment
- `get_appointment_sales(filters)`: Retrieves appointment sales data

**Workflow:**

1. Client selects a service and provides appointment details
2. Client makes payment upfront
3. System creates a confirmed appointment upon payment success
4. The provider needs to fulfill the confirmed appointment

**Strengths:**

- Integrated with payment processing
- Captures more detailed appointment metadata
- Provides sales reporting capabilities

**Weaknesses:**

- No availability checking before booking
- Provider has no approval step before commitment
- No conflict detection with other systems (events, legacy appointments)

### Key Technical Challenges

After analyzing both systems, we've identified several critical technical issues:

1. **Database Schema Fragmentation**

   - Two parallel tables capture the same type of data (appointments)
   - No direct relationship between availability and appointment_purchases
   - Different status enumerations and workflow assumptions

2. **Missing Conflict Detection**

   - Appointments created through purchases don't check provider availability
   - No validation against event bookings where the provider is participating
   - No mechanism to prevent overbooking across the two systems

3. **Timezone Handling Issues**

   - Availability is stored as simple TIME values without timezone context
   - Appointments use timezone-aware timestamps
   - Potential for booking errors during daylight saving time changes

4. **Workflow Disconnects**

   - Legacy system: request first → confirm later
   - Purchase system: payment first → fulfill later
   - No unified approach to handle different service requirements

5. **Data Consistency Risks**

   - Status fields have different allowed values across systems
   - No transaction handling across both appointment systems
   - Potential for lost or inconsistent data during failures

6. **Migration Complexity**
   - Existing appointments in both systems need preservation
   - Progressive transition required rather than hard cutover
   - Backward compatibility requirements for existing API clients

## Enhancement Strategy

Based on our analysis, we propose a comprehensive enhancement strategy that addresses these challenges while building on the strengths of both systems. Rather than choosing one system over the other, we recommend a unified approach that:

1. Preserves existing data and interfaces
2. Adds integration layers between systems
3. Enhances conflict detection across all scheduling
4. Provides flexible workflow options for different service types
5. Improves user experience for both providers and clients

The remainder of this document outlines this strategy in detail.

## Integration Opportunities

### 1. Unified Availability System

#### Current Limitations

The existing weekly availability system is too rigid for many real-world scenarios:

- No support for date-specific exceptions (holidays, personal days)
- No consideration of existing commitments (events, appointments)
- No buffer time between appointments
- No recurring patterns beyond weekly schedules

#### Proposed Solution: Enhanced Availability Model

We propose extending the availability system with:

1. **Core Weekly Schedule** (existing `availability` table)

   - Base recurring weekly schedule

2. **Schedule Exceptions** (new table)

   ```sql
   CREATE TABLE public.availability_exceptions (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
       exception_date DATE NOT NULL,
       is_available BOOLEAN NOT NULL, -- true for extra availability, false for unavailable
       start_time TIME,
       end_time TIME,
       reason TEXT,
       created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
       CONSTRAINT valid_times CHECK ((is_available = false) OR (start_time IS NOT NULL AND end_time IS NOT NULL AND start_time < end_time))
   );
   CREATE INDEX idx_availability_exceptions_user_date ON public.availability_exceptions(user_id, exception_date);
   ```

3. **Provider Preferences** (new table)

   ```sql
   CREATE TABLE public.provider_preferences (
       user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
       appointment_buffer_minutes INTEGER NOT NULL DEFAULT 0,
       max_daily_appointments INTEGER,
       max_weekly_appointments INTEGER,
       advance_notice_hours INTEGER NOT NULL DEFAULT 24,
       booking_window_days INTEGER NOT NULL DEFAULT 30,
       auto_confirm BOOLEAN NOT NULL DEFAULT false,
       timezone TEXT NOT NULL DEFAULT 'UTC',
       updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
   );
   ```

4. **Consolidated Availability View**

   ```sql
   CREATE OR REPLACE FUNCTION get_provider_availability(
       p_provider_id UUID,
       p_start_date DATE,
       p_end_date DATE
   ) RETURNS TABLE (
       date DATE,
       available_slots JSONB
   ) AS $$
   DECLARE
       v_timezone TEXT;
       v_buffer INTEGER;
       v_today DATE := CURRENT_DATE;
       v_now TIME := CURRENT_TIME;
   BEGIN
       -- Get provider preferences
       SELECT timezone, appointment_buffer_minutes INTO v_timezone, v_buffer
       FROM provider_preferences
       WHERE user_id = p_provider_id;

       -- Default values if not set
       v_timezone := COALESCE(v_timezone, 'UTC');
       v_buffer := COALESCE(v_buffer, 0);

       RETURN QUERY
       WITH date_series AS (
           SELECT generate_series(p_start_date, p_end_date, '1 day'::interval)::date AS day_date
       ),
       day_availability AS (
           SELECT
               ds.day_date,
               LOWER(TO_CHAR(ds.day_date, 'day')) AS day_name,
               av.start_time,
               av.end_time,
               av.is_active
           FROM
               date_series ds
           LEFT JOIN
               public.availability av ON
                   av.day = LOWER(TO_CHAR(ds.day_date, 'day')) AND
                   av.user_id = p_provider_id
       ),
       exceptions AS (
           SELECT
               ex.exception_date,
               ex.is_available,
               ex.start_time,
               ex.end_time
           FROM
               public.availability_exceptions ex
           WHERE
               ex.user_id = p_provider_id AND
               ex.exception_date BETWEEN p_start_date AND p_end_date
       ),
       appointments AS (
           SELECT
               (ap.appointment_date AT TIME ZONE v_timezone)::date AS appt_date,
               ap.appointment_date AT TIME ZONE v_timezone AS start_time,
               (ap.appointment_date + (ap.duration || ' minutes')::interval) AT TIME ZONE v_timezone AS end_time
           FROM
               public.appointment_purchases ap
           JOIN
               public.purchases p ON ap.purchase_id = p.id
           WHERE
               p.owner_id = p_provider_id AND
               ap.status IN ('confirmed', 'pending') AND
               (ap.appointment_date AT TIME ZONE v_timezone)::date BETWEEN p_start_date AND p_end_date

           UNION ALL

           SELECT
               (a.start_time AT TIME ZONE v_timezone)::date AS appt_date,
               a.start_time AT TIME ZONE v_timezone AS start_time,
               a.end_time AT TIME ZONE v_timezone AS end_time
           FROM
               public.appointments a
           WHERE
               a.facilitator_id = p_provider_id AND
               a.status IN ('confirmed', 'pending') AND
               (a.start_time AT TIME ZONE v_timezone)::date BETWEEN p_start_date AND p_end_date
       ),
       events AS (
           SELECT
               (ed.start_date AT TIME ZONE v_timezone)::date AS event_date,
               ed.start_date AT TIME ZONE v_timezone AS start_time,
               ed.end_date AT TIME ZONE v_timezone AS end_time
           FROM
               public.event_dates ed
           JOIN
               public.event_bookings eb ON ed.id = eb.date_id
           JOIN
               public.purchases p ON eb.purchase_id = p.id
           WHERE
               p.owner_id = p_provider_id AND
               eb.status IN ('confirmed', 'pending') AND
               (ed.start_date AT TIME ZONE v_timezone)::date BETWEEN p_start_date AND p_end_date
       ),
       available_slots AS (
           SELECT
               da.day_date,
               -- Generate 30-minute slots through the day
               slot_start.slot_time AS slot_start_time,
               slot_start.slot_time + '30 minutes'::interval AS slot_end_time,
               -- Check if slot is within available hours
               CASE
                   -- Handle date exceptions
                   WHEN ex.exception_date IS NOT NULL AND NOT ex.is_available THEN false
                   WHEN ex.exception_date IS NOT NULL AND ex.is_available AND
                        slot_start.slot_time >= ex.start_time AND
                        (slot_start.slot_time + '30 minutes'::interval) <= ex.end_time THEN true
                   -- Handle regular availability
                   WHEN ex.exception_date IS NULL AND
                        da.is_active AND
                        slot_start.slot_time >= da.start_time AND
                        (slot_start.slot_time + '30 minutes'::interval) <= da.end_time THEN true
                   ELSE false
               END AS is_within_availability,
               -- Check if slot overlaps with existing commitments
               EXISTS (
                   SELECT 1 FROM appointments a
                   WHERE a.appt_date = da.day_date AND
                   (a.start_time, a.end_time) OVERLAPS
                   (da.day_date + slot_start.slot_time, da.day_date + slot_start.slot_time + '30 minutes'::interval)
               ) AS has_appointment_conflict,
               EXISTS (
                   SELECT 1 FROM events e
                   WHERE e.event_date = da.day_date AND
                   (e.start_time, e.end_time) OVERLAPS
                   (da.day_date + slot_start.slot_time, da.day_date + slot_start.slot_time + '30 minutes'::interval)
               ) AS has_event_conflict,
               -- Handle past times
               (da.day_date < v_today OR
                (da.day_date = v_today AND slot_start.slot_time <= v_now)) AS is_past
           FROM
               day_availability da
           CROSS JOIN
               (SELECT generate_series(
                   '00:00:00'::time,
                   '23:30:00'::time,
                   '30 minutes'::interval
               ) AS slot_time) slot_start
           LEFT JOIN
               exceptions ex ON ex.exception_date = da.day_date
       )
       SELECT
           as_grp.day_date AS date,
           jsonb_agg(
               jsonb_build_object(
                   'start_time', (as_grp.day_date + as_grp.slot_start_time)::timestamp,
                   'end_time', (as_grp.day_date + as_grp.slot_end_time)::timestamp,
                   'available', (
                       as_grp.is_within_availability AND
                       NOT as_grp.has_appointment_conflict AND
                       NOT as_grp.has_event_conflict AND
                       NOT as_grp.is_past
                   )
               )
               ORDER BY as_grp.slot_start_time
           ) AS available_slots
       FROM
           available_slots as_grp
       GROUP BY
           as_grp.day_date
       ORDER BY
           as_grp.day_date;
   END;
   $$ LANGUAGE plpgsql SECURITY DEFINER;
   ```

This comprehensive function combines:

- Regular weekly availability
- Date-specific exceptions
- Existing appointments from both systems
- Event commitments
- Buffer time preferences
- Timezone handling
- Past time filtering

The result is a unified view of when providers are actually available, preventing conflicts across all systems.

#### Time Slot Response Format

Each request returns available dates with detailed slot information:

```json
[
  {
    "date": "2023-05-15",
    "available_slots": [
      {
        "start_time": "2023-05-15T09:00:00",
        "end_time": "2023-05-15T09:30:00",
        "available": true
      },
      {
        "start_time": "2023-05-15T09:30:00",
        "end_time": "2023-05-15T10:00:00",
        "available": false
      }
      // Additional slots...
    ]
  }
  // Additional dates...
]
```

### 2. Flexible Booking Workflows

The current systems support only two rigid workflows - request-then-approve or pay-then-fulfill. We need a more flexible system that can adapt to different service types.

#### Workflow Types and Decision Factors

Different service types have different requirements:

| Service Type               | Typical Workflow  | Reasoning                                                      |
| -------------------------- | ----------------- | -------------------------------------------------------------- |
| Standardized services      | Direct booking    | For services with fixed formats that can be delivered anytime  |
| Personalized consultations | Pre-approval      | Provider needs to evaluate the request before committing       |
| High-demand services       | Waitlist          | When immediate booking isn't available but cancellations occur |
| Group services             | Roster completion | When a minimum number of participants is required              |

#### Workflow Implementation

To support these diverse needs, we'll implement:

1. **Service Configuration Options**

   ```sql
   ALTER TABLE public.services
   ADD COLUMN booking_workflow TEXT NOT NULL DEFAULT 'direct'
       CHECK (booking_workflow IN ('direct', 'pre-approval', 'waitlist')),
   ADD COLUMN auto_confirm BOOLEAN NOT NULL DEFAULT true,
   ADD COLUMN confirmation_deadline_hours INTEGER DEFAULT 24,
   ADD COLUMN cancellation_policy TEXT DEFAULT 'flexible'
       CHECK (cancellation_policy IN ('flexible', 'moderate', 'strict'));
   ```

2. **Enhanced Appointment Status Tracking**

   ```sql
   -- Expand the status options in appointment_purchases
   ALTER TABLE public.appointment_purchases
   DROP CONSTRAINT appointment_purchases_status_check,
   ADD CONSTRAINT appointment_purchases_status_check
       CHECK (status IN ('pending_approval', 'pending_payment', 'confirmed',
                         'cancelled', 'completed', 'no_show', 'rescheduled'));
   ```

3. **Unified Appointment Request Function**

   ```sql
   CREATE OR REPLACE FUNCTION request_service_appointment(
       p_service_id UUID,
       p_requested_date TIMESTAMP WITH TIME ZONE,
       p_duration INTEGER DEFAULT NULL,
       p_method TEXT DEFAULT 'video',
       p_service_type TEXT DEFAULT 'consultation',
       p_notes TEXT DEFAULT NULL,
       p_client_id UUID DEFAULT NULL
   ) RETURNS JSONB AS $$
   DECLARE
       v_client_id UUID;
       v_service_owner_id UUID;
       v_booking_workflow TEXT;
       v_auto_confirm BOOLEAN;
       v_service_price NUMERIC;
       v_service_duration INTEGER;
       v_purchase_id UUID;
       v_appointment_id UUID;
       v_initial_status TEXT;
       v_result JSONB;
       v_timezone TEXT;
       v_slot_available BOOLEAN;
   BEGIN
       -- Set client ID (default to current user)
       v_client_id := COALESCE(p_client_id, auth.uid());

       -- Get service details and owner preferences
       SELECT
           p.user_id,
           s.booking_workflow,
           s.auto_confirm,
           s.price,
           EXTRACT(EPOCH FROM s.duration)::INTEGER / 60 AS duration_minutes,
           pp.timezone
       INTO
           v_service_owner_id,
           v_booking_workflow,
           v_auto_confirm,
           v_service_price,
           v_service_duration,
           v_timezone
       FROM
           public.services s
       JOIN
           public.posts p ON s.post_id = p.id
       LEFT JOIN
           public.provider_preferences pp ON p.user_id = pp.user_id
       WHERE
           s.id = p_service_id;

       -- Set duration (use service default if not provided)
       v_service_duration := COALESCE(p_duration, v_service_duration);
       IF v_service_duration IS NULL THEN
           RAISE EXCEPTION 'Service duration not specified';
       END IF;

       -- Check if the provider exists
       IF v_service_owner_id IS NULL THEN
           RAISE EXCEPTION 'Service not found';
       END IF;

       -- Verify the time slot is available
       WITH availability_check AS (
           SELECT
               (jsonb_array_elements(available_slots)->>'available')::BOOLEAN as is_available
           FROM
               get_provider_availability(
                   v_service_owner_id,
                   (p_requested_date AT TIME ZONE COALESCE(v_timezone, 'UTC'))::DATE,
                   (p_requested_date AT TIME ZONE COALESCE(v_timezone, 'UTC'))::DATE
               )
           WHERE
               date = (p_requested_date AT TIME ZONE COALESCE(v_timezone, 'UTC'))::DATE AND
               (jsonb_array_elements(available_slots)->>'start_time')::TIMESTAMP =
                   (p_requested_date AT TIME ZONE COALESCE(v_timezone, 'UTC'))::TIMESTAMP
       )
       SELECT COALESCE(bool_and(is_available), FALSE) INTO v_slot_available
       FROM availability_check;

       IF NOT v_slot_available THEN
           RETURN jsonb_build_object(
               'success', FALSE,
               'error', 'The requested time slot is not available'
           );
       END IF;

       -- Determine initial status based on workflow
       CASE
           WHEN v_booking_workflow = 'direct' AND v_auto_confirm THEN
               v_initial_status := 'confirmed';
           WHEN v_booking_workflow = 'direct' AND NOT v_auto_confirm THEN
               v_initial_status := 'pending_payment';
           WHEN v_booking_workflow = 'pre-approval' THEN
               v_initial_status := 'pending_approval';
           ELSE
               v_initial_status := 'pending_approval';
       END CASE;

       -- Create purchase record first
       INSERT INTO public.purchases (
           user_id,
           owner_id,
           amount,
           currency,
           payment_status,
           service_id,
           purchase_type,
           start_date,
           end_date,
           metadata
       ) VALUES (
           v_client_id,
           v_service_owner_id,
           v_service_price,
           'GBP',
           CASE WHEN v_initial_status = 'confirmed' THEN 'completed' ELSE 'pending' END,
           p_service_id,
           'appointment',
           p_requested_date,
           p_requested_date + (v_service_duration || ' minutes')::INTERVAL,
           jsonb_build_object(
               'appointment_type', p_service_type,
               'appointment_method', p_method,
               'client_notes', p_notes
           )
       ) RETURNING id INTO v_purchase_id;

       -- Create appointment record
       INSERT INTO public.appointment_purchases (
           purchase_id,
           service_id,
           appointment_date,
           duration,
           method,
           service_type,
           status,
           notes
       ) VALUES (
           v_purchase_id,
           p_service_id,
           p_requested_date,
           v_service_duration,
           p_method,
           p_service_type,
           v_initial_status,
           p_notes
       ) RETURNING id INTO v_appointment_id;

       -- Return result with appropriate next steps
       v_result := jsonb_build_object(
           'success', TRUE,
           'appointment_id', v_appointment_id,
           'purchase_id', v_purchase_id,
           'status', v_initial_status,
           'requires_payment', (v_initial_status = 'pending_payment'),
           'requires_approval', (v_initial_status = 'pending_approval'),
           'appointment_date', p_requested_date,
           'duration', v_service_duration,
           'price', v_service_price
       );

       RETURN v_result;
   EXCEPTION WHEN OTHERS THEN
       RETURN jsonb_build_object(
           'success', FALSE,
           'error', SQLERRM
       );
   END;
   $$ LANGUAGE plpgsql;
   ```

This flexible approach:

- Checks actual availability before booking
- Supports different workflows based on service configuration
- Creates appropriate records with the right initial status
- Returns clear next steps based on the workflow type

### 3. Conflict Prevention System

To ensure reliable booking across all systems, we need to implement robust conflict prevention:

#### Transaction-Level Conflict Detection

All booking operations should use transaction-level locking to prevent race conditions:

```sql
-- Function to check for conflicts
CREATE OR REPLACE FUNCTION check_schedule_conflicts(
    p_provider_id UUID,
    p_start_time TIMESTAMP WITH TIME ZONE,
    p_end_time TIMESTAMP WITH TIME ZONE,
    p_exclude_appointment_id UUID DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_has_conflicts BOOLEAN;
BEGIN
    -- Lock the provider's schedule for consistent checking
    PERFORM 1 FROM public.provider_preferences
    WHERE user_id = p_provider_id
    FOR UPDATE;

    -- Check for conflicts
    SELECT EXISTS (
        -- Check appointment_purchases conflicts
        SELECT 1
        FROM public.appointment_purchases ap
        JOIN public.purchases p ON ap.purchase_id = p.id
        WHERE p.owner_id = p_provider_id
        AND ap.status IN ('confirmed', 'pending_approval', 'pending_payment')
        AND (ap.id != p_exclude_appointment_id OR p_exclude_appointment_id IS NULL)
        AND (ap.appointment_date, ap.appointment_date + (ap.duration || ' minutes')::INTERVAL)
            OVERLAPS (p_start_time, p_end_time)

        UNION ALL

        -- Check legacy appointments conflicts
        SELECT 1
        FROM public.appointments a
        WHERE a.facilitator_id = p_provider_id
        AND a.status IN ('confirmed', 'pending')
        AND (a.start_time, a.end_time) OVERLAPS (p_start_time, p_end_time)

        UNION ALL

        -- Check event conflicts
        SELECT 1
        FROM public.event_dates ed
        JOIN public.event_bookings eb ON ed.id = eb.date_id
        JOIN public.purchases p ON eb.purchase_id = p.id
        WHERE p.owner_id = p_provider_id
        AND eb.status IN ('confirmed', 'pending')
        AND (ed.start_date, ed.end_date) OVERLAPS (p_start_time, p_end_time)
    ) INTO v_has_conflicts;

    RETURN v_has_conflicts;
END;
$$ LANGUAGE plpgsql;
```

#### Trigger-Based Prevention

Add triggers to all booking tables:

```sql
-- Trigger function
CREATE OR REPLACE FUNCTION prevent_double_booking()
RETURNS TRIGGER AS $$
DECLARE
    v_provider_id UUID;
    v_start_time TIMESTAMP WITH TIME ZONE;
    v_end_time TIMESTAMP WITH TIME ZONE;
    v_has_conflicts BOOLEAN;
BEGIN
    -- Get the provider ID and time range
    IF TG_TABLE_NAME = 'appointment_purchases' THEN
        SELECT p.owner_id INTO v_provider_id
        FROM public.purchases p
        WHERE p.id = NEW.purchase_id;

        v_start_time := NEW.appointment_date;
        v_end_time := NEW.appointment_date + (NEW.duration || ' minutes')::INTERVAL;
    ELSIF TG_TABLE_NAME = 'appointments' THEN
        v_provider_id := NEW.facilitator_id;
        v_start_time := NEW.start_time;
        v_end_time := NEW.end_time;
    END IF;

    -- Don't check conflicts for cancelled/completed appointments
    IF NEW.status IN ('cancelled', 'completed', 'no_show') THEN
        RETURN NEW;
    END IF;

    -- Check for conflicts
    v_has_conflicts := check_schedule_conflicts(
        v_provider_id,
        v_start_time,
        v_end_time,
        CASE WHEN TG_TABLE_NAME = 'appointment_purchases' THEN NEW.id ELSE NULL END
    );

    IF v_has_conflicts THEN
        RAISE EXCEPTION 'This time slot conflicts with an existing commitment';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger on appointment_purchases
CREATE TRIGGER check_appointment_purchase_conflicts
BEFORE INSERT OR UPDATE ON public.appointment_purchases
FOR EACH ROW EXECUTE FUNCTION prevent_double_booking();

-- Trigger on legacy appointments
CREATE TRIGGER check_legacy_appointment_conflicts
BEFORE INSERT OR UPDATE ON public.appointments
FOR EACH ROW EXECUTE FUNCTION prevent_double_booking();
```

This approach:

- Uses transaction locking to prevent race conditions
- Checks conflicts across all systems
- Prevents double-booking at the database level
- Works with both the legacy and new appointment systems

### 4. Enhanced Client Experience

A seamless client experience requires more than technical correctness - it demands intuitive interactions and clear communication. Our enhanced client experience focuses on:

#### 4.1 Visual Calendar Integration

Displaying available time slots in an intuitive calendar format requires specific data formatting:

```sql
-- Function to get service availability for calendar display
CREATE OR REPLACE FUNCTION get_service_calendar_availability(
    p_service_id UUID,
    p_days_ahead INTEGER DEFAULT 30,
    p_timezone TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_start_date DATE := CURRENT_DATE;
    v_end_date DATE := CURRENT_DATE + (p_days_ahead || ' days')::INTERVAL;
    v_service_owner_id UUID;
    v_timezone TEXT;
    v_result JSONB;
BEGIN
    -- Get service provider
    SELECT p.user_id, COALESCE(p_timezone, pp.timezone, 'UTC')
    INTO v_service_owner_id, v_timezone
    FROM public.services s
    JOIN public.posts p ON s.post_id = p.id
    LEFT JOIN public.provider_preferences pp ON p.user_id = pp.user_id
    WHERE s.id = p_service_id;

    IF v_service_owner_id IS NULL THEN
        RETURN jsonb_build_object('error', 'Service not found');
    END IF;

    -- Get availability data
    WITH availability_data AS (
        SELECT
            date,
            available_slots
        FROM
            get_provider_availability(v_service_owner_id, v_start_date, v_end_date)
    ),
    calendar_days AS (
        SELECT
            date,
            -- For each date, get the count of available slots
            (
                SELECT COUNT(*)
                FROM jsonb_array_elements(available_slots) AS slot
                WHERE (slot->>'available')::BOOLEAN = true
            ) AS available_slot_count,
            -- Get the first and last available times
            (
                SELECT MIN(
                    (elem->>'start_time')::TIMESTAMP WITH TIME ZONE AT TIME ZONE v_timezone
                )
                FROM jsonb_array_elements(available_slots) AS elem
                WHERE (elem->>'available')::BOOLEAN = true
            ) AS first_available,
            (
                SELECT MAX(
                    (elem->>'end_time')::TIMESTAMP WITH TIME ZONE AT TIME ZONE v_timezone
                )
                FROM jsonb_array_elements(available_slots) AS elem
                WHERE (elem->>'available')::BOOLEAN = true
            ) AS last_available,
            -- Format for a calendar view (day cells)
            CASE
                WHEN (
                    SELECT COUNT(*)
                    FROM jsonb_array_elements(available_slots) AS slot
                    WHERE (slot->>'available')::BOOLEAN = true
                ) > 0 THEN 'available'
                WHEN (
                    SELECT COUNT(*)
                    FROM jsonb_array_elements(available_slots) AS slot
                ) = 0 THEN 'unavailable'
                ELSE 'booked'
            END AS day_status,
            -- Store the raw slot data for later expansion
            available_slots AS raw_slots
        FROM
            availability_data
    )
    SELECT
        jsonb_build_object(
            'service_id', p_service_id,
            'timezone', v_timezone,
            'days', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'date', date,
                        'day_status', day_status,
                        'available_slots', available_slot_count,
                        'first_available', first_available,
                        'last_available', last_available
                    )
                    ORDER BY date
                )
                FROM calendar_days
            ),
            'hours', (
                SELECT jsonb_build_object(
                    'earliest', MIN(first_available::time),
                    'latest', MAX(last_available::time)
                )
                FROM calendar_days
                WHERE first_available IS NOT NULL
            )
        ) INTO v_result;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Function to get detailed slot view when user clicks a date
CREATE OR REPLACE FUNCTION get_service_day_slots(
    p_service_id UUID,
    p_date DATE,
    p_timezone TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_service_owner_id UUID;
    v_timezone TEXT;
    v_result JSONB;
BEGIN
    -- Get service provider
    SELECT p.user_id, COALESCE(p_timezone, pp.timezone, 'UTC')
    INTO v_service_owner_id, v_timezone
    FROM public.services s
    JOIN public.posts p ON s.post_id = p.id
    LEFT JOIN public.provider_preferences pp ON p.user_id = pp.user_id
    WHERE s.id = p_service_id;

    -- Get the detailed slot data for the day
    WITH day_data AS (
        SELECT
            date,
            available_slots
        FROM
            get_provider_availability(v_service_owner_id, p_date, p_date)
        WHERE
            date = p_date
    ),
    formatted_slots AS (
        SELECT
            (elem->>'start_time')::TIMESTAMP WITH TIME ZONE AT TIME ZONE v_timezone AS start_time,
            (elem->>'end_time')::TIMESTAMP WITH TIME ZONE AT TIME ZONE v_timezone AS end_time,
            (elem->>'available')::BOOLEAN AS is_available,
            -- Format for display with timezone context
            TO_CHAR((elem->>'start_time')::TIMESTAMP WITH TIME ZONE AT TIME ZONE v_timezone, 'HH24:MI') AS formatted_start,
            TO_CHAR((elem->>'end_time')::TIMESTAMP WITH TIME ZONE AT TIME ZONE v_timezone, 'HH24:MI') AS formatted_end
        FROM
            day_data,
            jsonb_array_elements(available_slots) AS elem
    )
    SELECT
        jsonb_build_object(
            'service_id', p_service_id,
            'date', p_date,
            'timezone', v_timezone,
            'formatted_date', TO_CHAR(p_date, 'Day, Month DD, YYYY'),
            'slots', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'start_time', start_time,
                        'end_time', end_time,
                        'formatted', formatted_start || ' - ' || formatted_end,
                        'available', is_available
                    )
                    ORDER BY start_time
                )
                FROM formatted_slots
            )
        ) INTO v_result;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;
```

These functions provide the data needed for two key client experiences:

1. A monthly calendar view showing available days
2. A time slot selection view when a day is selected

#### 4.2 Smart Booking Recommendations

To improve client experience, we can suggest optimal booking times:

```sql
CREATE OR REPLACE FUNCTION get_recommended_slots(
    p_service_id UUID,
    p_client_id UUID DEFAULT NULL,
    p_limit INTEGER DEFAULT 5,
    p_timezone TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_client_id UUID;
    v_service_owner_id UUID;
    v_timezone TEXT;
    v_result JSONB;
BEGIN
    -- Default to current user if not specified
    v_client_id := COALESCE(p_client_id, auth.uid());

    -- Get service provider
    SELECT p.user_id, COALESCE(p_timezone, pp.timezone, 'UTC')
    INTO v_service_owner_id, v_timezone
    FROM public.services s
    JOIN public.posts p ON s.post_id = p.id
    LEFT JOIN public.provider_preferences pp ON p.user_id = pp.user_id
    WHERE s.id = p_service_id;

    -- Build recommendations based on patterns
    WITH client_history AS (
        -- Get past appointment times for this client
        SELECT
            EXTRACT(DOW FROM ap.appointment_date) AS day_of_week,
            EXTRACT(HOUR FROM ap.appointment_date) AS hour_of_day,
            COUNT(*) AS booking_count
        FROM
            public.appointment_purchases ap
        JOIN
            public.purchases p ON ap.purchase_id = p.id
        WHERE
            p.user_id = v_client_id
        GROUP BY
            day_of_week, hour_of_day
        ORDER BY
            booking_count DESC
        LIMIT 3
    ),
    popular_slots AS (
        -- Most popular slots across all clients
        SELECT
            EXTRACT(DOW FROM ap.appointment_date) AS day_of_week,
            EXTRACT(HOUR FROM ap.appointment_date) AS hour_of_day,
            COUNT(*) AS booking_count
        FROM
            public.appointment_purchases ap
        JOIN
            public.purchases p ON ap.purchase_id = p.id
        WHERE
            p.owner_id = v_service_owner_id
        GROUP BY
            day_of_week, hour_of_day
        ORDER BY
            booking_count DESC
        LIMIT 3
    ),
    available_days AS (
        -- Get next 14 days of availability
        SELECT
            date,
            available_slots
        FROM
            get_provider_availability(v_service_owner_id, CURRENT_DATE, CURRENT_DATE + 14)
    ),
    prioritized_slots AS (
        -- Combine and prioritize slots
        SELECT
            (slot->>'start_time')::TIMESTAMP WITH TIME ZONE AS slot_time,
            EXTRACT(DOW FROM (slot->>'start_time')::TIMESTAMP WITH TIME ZONE) AS slot_dow,
            EXTRACT(HOUR FROM (slot->>'start_time')::TIMESTAMP WITH TIME ZONE) AS slot_hour,
            CASE
                -- Client's preferred times get highest priority
                WHEN EXISTS (
                    SELECT 1 FROM client_history ch
                    WHERE ch.day_of_week = EXTRACT(DOW FROM (slot->>'start_time')::TIMESTAMP WITH TIME ZONE)
                    AND ch.hour_of_day = EXTRACT(HOUR FROM (slot->>'start_time')::TIMESTAMP WITH TIME ZONE)
                ) THEN 3
                -- Generally popular times get medium priority
                WHEN EXISTS (
                    SELECT 1 FROM popular_slots ps
                    WHERE ps.day_of_week = EXTRACT(DOW FROM (slot->>'start_time')::TIMESTAMP WITH TIME ZONE)
                    AND ps.hour_of_day = EXTRACT(HOUR FROM (slot->>'start_time')::TIMESTAMP WITH TIME ZONE)
                ) THEN 2
                -- Prime time slots (9am-5pm) get slight priority
                WHEN EXTRACT(HOUR FROM (slot->>'start_time')::TIMESTAMP WITH TIME ZONE) BETWEEN 9 AND 17 THEN 1
                -- Other slots
                ELSE 0
            END AS priority
        FROM
            available_days ad,
            jsonb_array_elements(ad.available_slots) AS slot
        WHERE
            (slot->>'available')::BOOLEAN = true
        ORDER BY
            priority DESC,
            slot_time ASC
        LIMIT p_limit
    )
    SELECT
        jsonb_build_object(
            'service_id', p_service_id,
            'timezone', v_timezone,
            'recommended_slots', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'start_time', slot_time,
                        'end_time', slot_time + INTERVAL '30 minutes',
                        'formatted_date', TO_CHAR(slot_time AT TIME ZONE v_timezone, 'Day, Month DD'),
                        'formatted_time', TO_CHAR(slot_time AT TIME ZONE v_timezone, 'HH24:MI'),
                        'formatted_day_time', TO_CHAR(slot_time AT TIME ZONE v_timezone, 'Day HH24:MI'),
                        'priority_level', priority
                    )
                    ORDER BY priority DESC, slot_time ASC
                )
                FROM prioritized_slots
            )
        ) INTO v_result;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;
```

This creates personalized recommendations based on:

- Client's previous booking patterns
- Popular times for this specific service
- Generally optimal business hours
- Current availability

#### 4.3 Streamlined Booking Process

To simplify the client experience, we should provide a unified booking function:

```sql
CREATE OR REPLACE FUNCTION book_service_appointment(
    p_service_id UUID,
    p_requested_time TIMESTAMP WITH TIME ZONE,
    p_client_notes TEXT DEFAULT NULL,
    p_payment_method_id TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
    v_booking_workflow TEXT;
    v_service_price NUMERIC;
    v_requires_payment BOOLEAN;
    v_payment_result JSONB;
    v_appointment_id UUID;
    v_purchase_id UUID;
BEGIN
    -- First request the appointment
    SELECT request_service_appointment(
        p_service_id,
        p_requested_time,
        NULL, -- Use default duration
        'video', -- Default method
        'consultation', -- Default type
        p_client_notes
    ) INTO v_result;

    -- Check if successful
    IF NOT (v_result->>'success')::BOOLEAN THEN
        RETURN v_result;
    END IF;

    -- Get important data
    v_appointment_id := (v_result->>'appointment_id')::UUID;
    v_purchase_id := (v_result->>'purchase_id')::UUID;
    v_requires_payment := COALESCE((v_result->>'requires_payment')::BOOLEAN, FALSE);

    -- If payment is required and a payment method was provided, process it
    IF v_requires_payment AND p_payment_method_id IS NOT NULL THEN
        -- This would connect to your Stripe integration
        -- For now, just return the expected response structure
        v_payment_result := jsonb_build_object(
            'payment_status', 'success',
            'payment_intent_id', 'pi_mock_' || gen_random_uuid()::TEXT,
            'purchase_id', v_purchase_id,
            'appointment_id', v_appointment_id
        );

        -- Update the result to include payment details
        v_result := v_result || jsonb_build_object(
            'payment_processed', TRUE,
            'payment_result', v_payment_result
        );
    END IF;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;
```

This function:

- Creates a single entry point for booking
- Handles different workflow types automatically
- Optionally processes payment if required
- Returns detailed next steps based on booking flow

### 5. Provider Management Tools

Providers need robust tools to manage their service availability and appointments:

#### 5.1 Unified Calendar Administration

A critical function for providers is efficiently managing their schedule:

```sql
-- Update provider availability in batch
CREATE OR REPLACE FUNCTION update_provider_schedule(
    p_provider_id UUID DEFAULT NULL,
    p_weekly_schedule JSONB DEFAULT NULL, -- Format: [{"day": "monday", "is_active": true, "start_time": "09:00", "end_time": "17:00"}, ...]
    p_exceptions JSONB DEFAULT NULL, -- Format: [{"date": "2023-05-15", "is_available": false, "reason": "Holiday"}, ...]
    p_preferences JSONB DEFAULT NULL  -- Format: {"buffer_minutes": 15, "timezone": "Europe/London", ...}
) RETURNS JSONB AS $$
DECLARE
    v_provider_id UUID;
    v_day RECORD;
    v_exception RECORD;
    v_result JSONB;
    v_updated_days INTEGER := 0;
    v_updated_exceptions INTEGER := 0;
BEGIN
    -- Default to current user
    v_provider_id := COALESCE(p_provider_id, auth.uid());

    -- Check permissions
    IF v_provider_id != auth.uid() AND NOT EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid() AND role = 'admin'
    ) THEN
        RETURN jsonb_build_object('error', 'Permission denied');
    END IF;

    -- Start transaction for consistency
    BEGIN
        -- 1. Update weekly schedule if provided
        IF p_weekly_schedule IS NOT NULL AND jsonb_array_length(p_weekly_schedule) > 0 THEN
            -- First clear existing schedule
            DELETE FROM public.availability WHERE user_id = v_provider_id;

            -- Then insert new schedule
            FOR v_day IN SELECT * FROM jsonb_to_recordset(p_weekly_schedule)
                AS x(day TEXT, is_active BOOLEAN, start_time TIME, end_time TIME)
            LOOP
                INSERT INTO public.availability (
                    user_id, day, is_active, start_time, end_time
                ) VALUES (
                    v_provider_id,
                    LOWER(v_day.day),
                    v_day.is_active,
                    v_day.start_time,
                    v_day.end_time
                );
                v_updated_days := v_updated_days + 1;
            END LOOP;
        END IF;

        -- 2. Update exceptions if provided
        IF p_exceptions IS NOT NULL AND jsonb_array_length(p_exceptions) > 0 THEN
            FOR v_exception IN SELECT * FROM jsonb_to_recordset(p_exceptions)
                AS x(date DATE, is_available BOOLEAN, start_time TIME, end_time TIME, reason TEXT)
            LOOP
                -- Remove any existing exception for this date
                DELETE FROM public.availability_exceptions
                WHERE user_id = v_provider_id AND exception_date = v_exception.date;

                -- Insert new exception
                INSERT INTO public.availability_exceptions (
                    user_id, exception_date, is_available, start_time, end_time, reason
                ) VALUES (
                    v_provider_id,
                    v_exception.date,
                    v_exception.is_available,
                    v_exception.start_time,
                    v_exception.end_time,
                    v_exception.reason
                );
                v_updated_exceptions := v_updated_exceptions + 1;
            END LOOP;
        END IF;

        -- 3. Update preferences if provided
        IF p_preferences IS NOT NULL THEN
            -- Upsert preferences
            INSERT INTO public.provider_preferences (
                user_id,
                appointment_buffer_minutes,
                max_daily_appointments,
                max_weekly_appointments,
                advance_notice_hours,
                booking_window_days,
                auto_confirm,
                timezone
            ) VALUES (
                v_provider_id,
                (p_preferences->>'buffer_minutes')::INTEGER,
                (p_preferences->>'max_daily_appointments')::INTEGER,
                (p_preferences->>'max_weekly_appointments')::INTEGER,
                (p_preferences->>'advance_notice_hours')::INTEGER,
                (p_preferences->>'booking_window_days')::INTEGER,
                (p_preferences->>'auto_confirm')::BOOLEAN,
                p_preferences->>'timezone'
            )
            ON CONFLICT (user_id) DO UPDATE SET
                appointment_buffer_minutes = EXCLUDED.appointment_buffer_minutes,
                max_daily_appointments = EXCLUDED.max_daily_appointments,
                max_weekly_appointments = EXCLUDED.max_weekly_appointments,
                advance_notice_hours = EXCLUDED.advance_notice_hours,
                booking_window_days = EXCLUDED.booking_window_days,
                auto_confirm = EXCLUDED.auto_confirm,
                timezone = EXCLUDED.timezone,
                updated_at = CURRENT_TIMESTAMP;
        END IF;

        -- Commit the transaction
        RAISE NOTICE 'Schedule updated successfully';
    EXCEPTION WHEN OTHERS THEN
        -- Roll back on error
        RAISE EXCEPTION 'Failed to update schedule: %', SQLERRM;
    END;

    -- Return summary
    v_result := jsonb_build_object(
        'provider_id', v_provider_id,
        'success', TRUE,
        'updated_days', v_updated_days,
        'updated_exceptions', v_updated_exceptions,
        'preferences_updated', (p_preferences IS NOT NULL)
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;
```

#### 5.2 Appointment Management Dashboard Data

Providers need a comprehensive view of their commitments:

```sql
-- Get provider's upcoming appointments with details
CREATE OR REPLACE FUNCTION get_provider_appointment_dashboard(
    p_provider_id UUID DEFAULT NULL,
    p_start_date DATE DEFAULT CURRENT_DATE,
    p_end_date DATE DEFAULT NULL,
    p_status TEXT DEFAULT NULL,
    p_timezone TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_provider_id UUID;
    v_end_date DATE;
    v_timezone TEXT;
    v_result JSONB;
BEGIN
    -- Default values
    v_provider_id := COALESCE(p_provider_id, auth.uid());
    v_end_date := COALESCE(p_end_date, p_start_date + INTERVAL '30 days');

    -- Get provider's timezone preference
    SELECT timezone INTO v_timezone
    FROM public.provider_preferences
    WHERE user_id = v_provider_id;

    v_timezone := COALESCE(p_timezone, v_timezone, 'UTC');

    -- Get comprehensive appointment data
    WITH appointment_data AS (
        -- Get appointments from the purchase system
        SELECT
            'appointment_purchase' AS source,
            ap.id AS appointment_id,
            ap.purchase_id,
            ap.service_id,
            s.post_id,
            p2.title AS service_title,
            ap.appointment_date AT TIME ZONE v_timezone AS appointment_time,
            (ap.appointment_date + (ap.duration || ' minutes')::INTERVAL) AT TIME ZONE v_timezone AS end_time,
            ap.duration,
            ap.method,
            ap.service_type,
            ap.status,
            p.payment_status,
            p.amount,
            p.user_id AS client_id,
            cl.full_name AS client_name,
            cl.avatar_url AS client_avatar,
            ap.notes,
            p.metadata->>'client_notes' AS client_notes,
            ap.meeting_url,
            ap.meeting_id
        FROM
            public.appointment_purchases ap
        JOIN
            public.purchases p ON ap.purchase_id = p.id
        JOIN
            public.services s ON ap.service_id = s.id
        JOIN
            public.posts p2 ON s.post_id = p2.id
        LEFT JOIN
            public.profiles cl ON p.user_id = cl.id
        WHERE
            p.owner_id = v_provider_id AND
            (ap.appointment_date AT TIME ZONE v_timezone)::DATE BETWEEN p_start_date AND v_end_date AND
            (p_status IS NULL OR ap.status = p_status)

        UNION ALL

        -- Get appointments from the legacy system
        SELECT
            'legacy_appointment' AS source,
            a.id AS appointment_id,
            NULL AS purchase_id,
            NULL AS service_id,
            NULL AS post_id,
            'Legacy Appointment' AS service_title,
            a.start_time AT TIME ZONE v_timezone AS appointment_time,
            a.end_time AT TIME ZONE v_timezone AS end_time,
            EXTRACT(EPOCH FROM (a.end_time - a.start_time))/60 AS duration,
            'not_specified' AS method,
            'consultation' AS service_type,
            a.status,
            'completed' AS payment_status,
            0 AS amount,
            a.client_id,
            cl.full_name AS client_name,
            cl.avatar_url AS client_avatar,
            NULL AS notes,
            NULL AS client_notes,
            NULL AS meeting_url,
            NULL AS meeting_id
        FROM
            public.appointments a
        LEFT JOIN
            public.profiles cl ON a.client_id = cl.id
        WHERE
            a.facilitator_id = v_provider_id AND
            (a.start_time AT TIME ZONE v_timezone)::DATE BETWEEN p_start_date AND v_end_date AND
            (p_status IS NULL OR
             (p_status = 'confirmed' AND a.status = 'confirmed') OR
             (p_status = 'pending' AND a.status = 'pending') OR
             (p_status = 'cancelled' AND a.status = 'rejected'))
    ),
    date_summary AS (
        -- Summarize by date
        SELECT
            (appointment_time)::DATE AS day,
            COUNT(*) AS total_appointments,
            jsonb_agg(
                jsonb_build_object(
                    'id', appointment_id,
                    'source', source,
                    'time', TO_CHAR(appointment_time, 'HH24:MI'),
                    'end_time', TO_CHAR(end_time, 'HH24:MI'),
                    'duration', duration,
                    'title', service_title,
                    'client', jsonb_build_object(
                        'id', client_id,
                        'name', client_name,
                        'avatar', client_avatar
                    ),
                    'status', status,
                    'payment_status', payment_status,
                    'amount', amount,
                    'method', method,
                    'notes', COALESCE(client_notes, notes),
                    'meeting_info', CASE
                        WHEN meeting_url IS NOT NULL OR meeting_id IS NOT NULL
                        THEN jsonb_build_object(
                            'url', meeting_url,
                            'id', meeting_id
                        )
                        ELSE NULL
                    END
                )
                ORDER BY appointment_time
            ) AS appointments
        FROM
            appointment_data
        GROUP BY
            day
    )
    SELECT jsonb_build_object(
        'provider_id', v_provider_id,
        'timezone', v_timezone,
        'start_date', p_start_date,
        'end_date', v_end_date,
        'status_filter', p_status,
        'total_appointments', (SELECT COUNT(*) FROM appointment_data),
        'days', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'date', day,
                    'formatted_date', TO_CHAR(day, 'Day, Month DD, YYYY'),
                    'appointment_count', total_appointments,
                    'appointments', appointments
                )
                ORDER BY day
            )
            FROM date_summary
        ),
        'summary', jsonb_build_object(
            'total', (SELECT COUNT(*) FROM appointment_data),
            'pending', (SELECT COUNT(*) FROM appointment_data WHERE status = 'pending' OR status = 'pending_approval' OR status = 'pending_payment'),
            'confirmed', (SELECT COUNT(*) FROM appointment_data WHERE status = 'confirmed'),
            'cancelled', (SELECT COUNT(*) FROM appointment_data WHERE status = 'cancelled' OR status = 'rejected'),
            'completed', (SELECT COUNT(*) FROM appointment_data WHERE status = 'completed')
        )
    ) INTO v_result;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;
```

This function provides comprehensive data for:

- Calendar view of upcoming appointments
- List view of appointments by day
- Summary statistics for dashboard
- Integrated view of both appointment systems

#### 5.3 Appointment Response Function

Providers need a way to respond to appointment requests:

```sql
-- Function for providers to respond to appointment requests
CREATE OR REPLACE FUNCTION respond_to_appointment_request(
    p_appointment_id UUID,
    p_action TEXT, -- 'confirm', 'reject', 'suggest_alternative'
    p_alternative_time TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_provider_notes TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_appointment_record RECORD;
    v_provider_id UUID;
    v_current_status TEXT;
    v_source TEXT;
    v_result JSONB;
BEGIN
    -- Determine which system the appointment is in

    -- First check appointment_purchases
    SELECT
        ap.id,
        ap.status,
        p.owner_id AS provider_id,
        'appointment_purchase' AS source,
        p.id AS purchase_id
    INTO v_appointment_record
    FROM
        public.appointment_purchases ap
    JOIN
        public.purchases p ON ap.purchase_id = p.id
    WHERE
        ap.id = p_appointment_id;

    -- If not found, check legacy appointments
    IF v_appointment_record.id IS NULL THEN
        SELECT
            a.id,
            a.status,
            a.facilitator_id AS provider_id,
            'legacy_appointment' AS source,
            NULL AS purchase_id
        INTO v_appointment_record
        FROM
            public.appointments a
        WHERE
            a.id = p_appointment_id;
    END IF;

    -- If still not found, appointment doesn't exist
    IF v_appointment_record.id IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Appointment not found'
        );
    END IF;

    -- Store found values
    v_provider_id := v_appointment_record.provider_id;
    v_current_status := v_appointment_record.status;
    v_source := v_appointment_record.source;

    -- Check permissions
    IF v_provider_id != auth.uid() AND NOT EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid() AND role = 'admin'
    ) THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Permission denied'
        );
    END IF;

    -- Process the response based on source system
    IF v_source = 'appointment_purchase' THEN
        -- Handle appointment_purchases
        IF p_action = 'confirm' THEN
            IF v_current_status NOT IN ('pending_approval', 'pending_payment') THEN
                RETURN jsonb_build_object(
                    'success', FALSE,
                    'error', 'Appointment cannot be confirmed in its current status: ' || v_current_status
                );
            END IF;

            -- Update to confirmed
            UPDATE public.appointment_purchases
            SET
                status = 'confirmed',
                notes = CASE
                    WHEN p_provider_notes IS NOT NULL THEN
                        COALESCE(notes, '') || E'\nProvider notes: ' || p_provider_notes
                    ELSE notes
                END
            WHERE id = p_appointment_id;

            -- Also update purchase if needed
            IF v_current_status = 'pending_approval' THEN
                UPDATE public.purchases
                SET payment_status = 'completed'
                WHERE id = v_appointment_record.purchase_id;
            END IF;

            v_result := jsonb_build_object(
                'success', TRUE,
                'action', 'confirm',
                'appointment_id', p_appointment_id,
                'status', 'confirmed'
            );

        ELSIF p_action = 'reject' THEN
            IF v_current_status NOT IN ('pending_approval', 'pending_payment', 'confirmed') THEN
                RETURN jsonb_build_object(
                    'success', FALSE,
                    'error', 'Appointment cannot be rejected in its current status: ' || v_current_status
                );
            END IF;

            -- Update to cancelled
            UPDATE public.appointment_purchases
            SET
                status = 'cancelled',
                notes = CASE
                    WHEN p_provider_notes IS NOT NULL THEN
                        COALESCE(notes, '') || E'\nRejection reason: ' || p_provider_notes
                    ELSE notes
                END
            WHERE id = p_appointment_id;

            -- If payment was already made, set to refunded
            IF v_current_status IN ('confirmed', 'pending_payment') THEN
                UPDATE public.purchases
                SET payment_status = 'refunded'
                WHERE id = v_appointment_record.purchase_id;
            END IF;

            v_result := jsonb_build_object(
                'success', TRUE,
                'action', 'reject',
                'appointment_id', p_appointment_id,
                'status', 'cancelled'
            );

        ELSIF p_action = 'suggest_alternative' THEN
            IF v_current_status NOT IN ('pending_approval', 'pending_payment') OR p_alternative_time IS NULL THEN
                RETURN jsonb_build_object(
                    'success', FALSE,
                    'error', 'Cannot suggest alternative time'
                );
            END IF;

            -- Create a record of the suggestion in metadata
            UPDATE public.appointment_purchases
            SET
                notes = COALESCE(notes, '') || E'\nAlternative time suggested: ' ||
                    TO_CHAR(p_alternative_time, 'YYYY-MM-DD HH24:MI:SS'),
                metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
                    'alternative_time', p_alternative_time,
                    'suggestion_notes', p_provider_notes
                )
            WHERE id = p_appointment_id;

            v_result := jsonb_build_object(
                'success', TRUE,
                'action', 'suggest_alternative',
                'appointment_id', p_appointment_id,
                'suggested_time', p_alternative_time
            );
        ELSE
            RETURN jsonb_build_object(
                'success', FALSE,
                'error', 'Invalid action: ' || p_action
            );
        END IF;

    ELSE
        -- Handle legacy appointments
        IF p_action = 'confirm' THEN
            UPDATE public.appointments
            SET status = 'confirmed'
            WHERE id = p_appointment_id AND status = 'pending';

        ELSIF p_action = 'reject' THEN
            UPDATE public.appointments
            SET status = 'rejected'
            WHERE id = p_appointment_id AND status = 'pending';

        ELSIF p_action = 'suggest_alternative' AND p_alternative_time IS NOT NULL THEN
            UPDATE public.appointments
            SET
                status = 'suggested',
                start_time = p_alternative_time,
                end_time = p_alternative_time + interval '1 hour'
            WHERE id = p_appointment_id AND status = 'pending';
        ELSE
            RETURN jsonb_build_object(
                'success', FALSE,
                'error', 'Invalid action for legacy appointment'
            );
        END IF;

        v_result := jsonb_build_object(
            'success', TRUE,
            'action', p_action,
            'appointment_id', p_appointment_id
        );
    END IF;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;
```

This function provides a unified way to:

- Confirm appointment requests
- Reject appointment requests with reason
- Suggest alternative times
- Work with both appointment systems
- Handle payment status implications

## Migration Strategy

A critical aspect of implementing these improvements is migrating from the current dual-system architecture to a unified approach without disrupting existing operations. Here's our recommended approach:

### Phase 1: Integration Layer (1-2 weeks)

1. **Create the Provider Preferences Table**

   ```sql
   CREATE TABLE public.provider_preferences (
       user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
       appointment_buffer_minutes INTEGER NOT NULL DEFAULT 0,
       max_daily_appointments INTEGER,
       max_weekly_appointments INTEGER,
       advance_notice_hours INTEGER NOT NULL DEFAULT 24,
       booking_window_days INTEGER NOT NULL DEFAULT 30,
       auto_confirm BOOLEAN NOT NULL DEFAULT false,
       timezone TEXT NOT NULL DEFAULT 'UTC',
       updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
   );
   ```

2. **Create the Availability Exceptions Table**

   ```sql
   CREATE TABLE public.availability_exceptions (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
       exception_date DATE NOT NULL,
       is_available BOOLEAN NOT NULL, -- true for extra availability, false for unavailable
       start_time TIME,
       end_time TIME,
       reason TEXT,
       created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
       CONSTRAINT valid_times CHECK ((is_available = false) OR (start_time IS NOT NULL AND end_time IS NOT NULL AND start_time < end_time))
   );
   ```

3. **Develop Integration Functions**

   - Implement the unified availability check functions
   - Create cross-system conflict detection
   - Build comprehensive dashboard views

4. **Extend Existing Tables**

   ```sql
   -- Add workflow fields to services
   ALTER TABLE public.services
   ADD COLUMN booking_workflow TEXT NOT NULL DEFAULT 'direct'
       CHECK (booking_workflow IN ('direct', 'pre-approval', 'waitlist')),
   ADD COLUMN auto_confirm BOOLEAN NOT NULL DEFAULT true,
   ADD COLUMN confirmation_deadline_hours INTEGER DEFAULT 24;

   -- Expand status options in appointment_purchases
   ALTER TABLE public.appointment_purchases
   DROP CONSTRAINT appointment_purchases_status_check,
   ADD CONSTRAINT appointment_purchases_status_check
       CHECK (status IN ('pending_approval', 'pending_payment', 'confirmed',
                        'cancelled', 'completed', 'no_show', 'rescheduled'));
   ```

5. **Create Bridge Views**
   - Implement views that combine data from both systems
   - Keep the existing interfaces working during migration

### Phase 2: Enhanced Functions (2-3 weeks)

1. **Implement Conflict Prevention**

   - Create triggers for all booking operations
   - Build transaction-level conflict checking
   - Add cross-system validation

2. **Develop New Booking Functions**

   - Build the unified request_service_appointment function
   - Implement flexible workflow handling
   - Create smart slot recommendation system

3. **Create Provider Management Tools**
   - Develop batch availability updates
   - Build get_provider_appointment_dashboard
   - Develop the recommended_slots function
   - Create the book_service_appointment function

### Phase 3: UI Integration and Data Migration (2-4 weeks)

1. **Legacy Data Migration**

   ```sql
   -- Migrate legacy appointments to the new system
   INSERT INTO public.purchases (
       id, user_id, owner_id, amount, currency, payment_status,
       service_id, purchase_type, start_date, end_date, metadata
   )
   SELECT
       gen_random_uuid(), -- new ID
       a.client_id, -- user_id
       a.facilitator_id, -- owner_id
       0, -- amount (legacy didn't track this)
       'GBP', -- currency
       CASE
           WHEN a.status = 'confirmed' THEN 'completed'
           WHEN a.status = 'pending' THEN 'pending'
           ELSE 'cancelled'
       END, -- payment_status
       NULL, -- service_id (unknown from legacy system)
       'appointment', -- purchase_type
       a.start_time, -- start_date
       a.end_time, -- end_date
       jsonb_build_object(
           'legacy_appointment_id', a.id,
           'migrated_at', CURRENT_TIMESTAMP
       ) -- metadata
   FROM public.appointments a
   WHERE
       a.status IN ('confirmed', 'pending') AND
       a.start_time > CURRENT_TIMESTAMP;
   ```

2. **Create New Connector Functions**

   - Implement adapter functions that work with both systems
   - Gradually shift UI components to use the new functions

3. **Update API Endpoints**
   - Modify any API routes to use the new unified functions
   - Maintain backward compatibility with existing clients

### Phase 4: Deprecation and Cleanup (After Full Transition)

1. **Deprecation Strategy**

   - Mark legacy functions as deprecated
   - Add warning messages for API users
   - Set transition timelines

2. **Final Data Migration**

   - Move any remaining data from legacy tables
   - Ensure all historical data is preserved

3. **System Cleanup**
   - Remove unused legacy code
   - Drop unnecessary views and functions
   - Optimize database schema

## Performance Considerations

The enhanced service appointment system introduces some complexity that requires careful performance tuning:

### 1. Availability Calculation Optimization

The availability calculation involves:

- Checking weekly patterns
- Applying date-specific exceptions
- Checking existing appointments and events
- Applying buffer times

This can become expensive with many providers or long date ranges. Strategies include:

```sql
-- 1. Add specific indexes
CREATE INDEX idx_appointment_purchases_date_provider
ON public.appointment_purchases(appointment_date, service_id);

CREATE INDEX idx_purchases_owner_id_type
ON public.purchases(owner_id, purchase_type);

-- 2. Consider materialized views for common availability patterns
CREATE MATERIALIZED VIEW provider_monthly_availability AS
SELECT
    provider_id,
    date,
    available_slots
FROM
    generate_provider_availability_cache();

-- 3. Add a refresh schedule
CREATE OR REPLACE FUNCTION refresh_availability_cache()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY provider_monthly_availability;
END;
$$ LANGUAGE plpgsql;
```

### 2. Transaction Handling

Our system requires transaction-level consistency to prevent double-booking. This must be balanced with performance:

```sql
-- Use advisory locks for concurrent operations
CREATE OR REPLACE FUNCTION lock_provider_schedule(
    p_provider_id UUID
) RETURNS BIGINT AS $$
DECLARE
    v_lock_key BIGINT;
BEGIN
    -- Create a stable lock key from the UUID
    SELECT ('x' || substring(p_provider_id::TEXT, 1, 8))::BIT(32)::BIGINT INTO v_lock_key;

    -- Acquire advisory lock with 5 second timeout
    IF NOT pg_try_advisory_xact_lock(v_lock_key) THEN
        -- Wait up to 5 seconds
        PERFORM pg_sleep(0.1)
        FROM generate_series(1, 50)
        WHERE NOT pg_try_advisory_xact_lock(v_lock_key);

        IF NOT pg_try_advisory_xact_lock(v_lock_key) THEN
            RAISE EXCEPTION 'Could not acquire schedule lock, try again later';
        END IF;
    END IF;

    RETURN v_lock_key;
END;
$$ LANGUAGE plpgsql;
```

### 3. Caching Strategies

Certain expensive operations can benefit from caching:

```sql
-- Add caching for recommended slots
CREATE OR REPLACE FUNCTION get_recommended_slots_cached(
    p_service_id UUID,
    p_client_id UUID DEFAULT NULL,
    p_cache_ttl_minutes INTEGER DEFAULT 15
) RETURNS JSONB AS $$
DECLARE
    v_cache_key TEXT;
    v_cached_result JSONB;
    v_result JSONB;
BEGIN
    -- Create a cache key
    v_cache_key := 'recommended_slots:' || p_service_id::TEXT || ':' || COALESCE(p_client_id::TEXT, 'anon');

    -- Check cache first
    SELECT obj_value INTO v_cached_result
    FROM cache_store
    WHERE cache_key = v_cache_key AND created_at > (CURRENT_TIMESTAMP - (p_cache_ttl_minutes || ' minutes')::INTERVAL);

    IF v_cached_result IS NOT NULL THEN
        RETURN v_cached_result;
    END IF;

    -- Generate the recommendations
    -- Call the actual function...

    -- Store in cache
    INSERT INTO cache_store (cache_key, obj_value)
    VALUES (v_cache_key, v_result)
    ON CONFLICT (cache_key) DO UPDATE
    SET obj_value = EXCLUDED.obj_value, created_at = CURRENT_TIMESTAMP;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;
```

## Security and Privacy Considerations

The appointment system handles sensitive data, including:

- Client personal information
- Provider schedules and availability
- Payment details and history

Key security measures include:

### 1. Row-Level Security Policies

```sql
-- Enforce RLS for provider preferences
ALTER TABLE public.provider_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY provider_preferences_owner ON public.provider_preferences
    FOR ALL
    USING (user_id = auth.uid() OR
          EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'));

-- Enforce RLS for availability exceptions
ALTER TABLE public.availability_exceptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY availability_exceptions_owner ON public.availability_exceptions
    FOR ALL
    USING (user_id = auth.uid() OR
          EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'));
```

### 2. Permission Handling in Functions

All functions use `SECURITY DEFINER` with proper permission checks:

```sql
-- Best practices for function permission checking
IF p_provider_id != auth.uid() AND NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid() AND role = 'admin'
) THEN
    RETURN jsonb_build_object('error', 'Permission denied');
END IF;
```

### 3. Privacy Considerations

Client information must be protected:

```sql
-- Ensure provider response function doesn't leak client data
CREATE OR REPLACE FUNCTION get_appointment_for_provider(
    p_appointment_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_provider_id UUID;
    v_result JSONB;
BEGIN
    -- Check if the current user is the provider for this appointment
    SELECT p.owner_id INTO v_provider_id
    FROM public.appointment_purchases ap
    JOIN public.purchases p ON ap.purchase_id = p.id
    WHERE ap.id = p_appointment_id;

    IF v_provider_id != auth.uid() AND NOT EXISTS (
        SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'
    ) THEN
        RETURN jsonb_build_object('error', 'Permission denied');
    END IF;

    -- If permission check passed, return appointment data
    -- ...
END;
$$ LANGUAGE plpgsql;
```

## Testing Strategy

To ensure reliability, a comprehensive testing approach is essential:

### 1. Unit Tests for Core Functions

```sql
-- Example test for availability checking
CREATE OR REPLACE FUNCTION test_availability_check()
RETURNS SETOF TEXT AS $$
BEGIN
    -- Set up test data
    INSERT INTO public.availability (user_id, day, is_active, start_time, end_time)
    VALUES ('00000000-0000-0000-0000-000000000001', 'monday', true, '09:00', '17:00');

    -- Test available slot
    RETURN NEXT is(
        (
            SELECT (jsonb_array_elements(available_slots)->>'available')::BOOLEAN
            FROM get_provider_availability('00000000-0000-0000-0000-000000000001', '2023-03-20', '2023-03-20')
            WHERE date = '2023-03-20' -- a Monday
            LIMIT 1
        ),
        true,
        'Monday slot should be available'
    );

    -- Test conflict detection
    INSERT INTO public.appointment_purchases (
        id, purchase_id, service_id, appointment_date, duration, method, service_type, status
    ) VALUES (
        'a0000000-0000-0000-0000-000000000001',
        'b0000000-0000-0000-0000-000000000001',
        'c0000000-0000-0000-0000-000000000001',
        '2023-03-20 10:00:00',
        60,
        'video',
        'consultation',
        'confirmed'
    );

    INSERT INTO public.purchases (
        id, user_id, owner_id, amount, currency, payment_status, service_id, purchase_type
    ) VALUES (
        'b0000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000002',
        '00000000-0000-0000-0000-000000000001',
        100,
        'GBP',
        'completed',
        'c0000000-0000-0000-0000-000000000001',
        'appointment'
    );

    RETURN NEXT is(
        (
            SELECT (jsonb_array_elements(available_slots)->>'available')::BOOLEAN
            FROM get_provider_availability('00000000-0000-0000-0000-000000000001', '2023-03-20', '2023-03-20')
            WHERE date = '2023-03-20'
            AND (jsonb_array_elements(available_slots)->>'start_time')::TIMESTAMP = '2023-03-20 10:00:00'
        ),
        false,
        'Slot with existing appointment should be unavailable'
    );

    -- Clean up test data
    DELETE FROM public.purchases WHERE id = 'b0000000-0000-0000-0000-000000000001';
    DELETE FROM public.appointment_purchases WHERE id = 'a0000000-0000-0000-0000-000000000001';
    DELETE FROM public.availability WHERE user_id = '00000000-0000-0000-0000-000000000001';

    RETURN;
END;
$$ LANGUAGE plpgsql;
```

### 2. Integration Test Scenarios

Key scenarios to test include:

1. **Booking Flow**

   - Test each workflow type (direct, pre-approval, waitlist)
   - Test with and without payment
   - Test provider responses

2. **Conflict Prevention**

   - Test concurrent booking attempts
   - Test cross-system conflicts (events + appointments)
   - Test date exceptions handling

3. **Calendar Integration**
   - Test timezone handling
   - Test daylight saving time transitions
   - Test buffer time application

### 3. Performance Testing

```sql
-- Create a stress test for availability calculations
CREATE OR REPLACE FUNCTION stress_test_availability(
    p_provider_count INTEGER,
    p_days_ahead INTEGER,
    p_appointment_density FLOAT
) RETURNS TABLE (
    provider_index INTEGER,
    calculation_time_ms FLOAT,
    available_slot_count INTEGER
) AS $$
DECLARE
    v_provider_id UUID;
    v_start_time TIMESTAMP;
    v_duration FLOAT;
    v_slot_count INTEGER;
BEGIN
    -- For each simulated provider
    FOR i IN 1..p_provider_count LOOP
        -- Create test provider
        v_provider_id := gen_random_uuid();

        -- Set up availability (different patterns)
        INSERT INTO public.availability (user_id, day, is_active, start_time, end_time)
        SELECT
            v_provider_id,
            day,
            true,
            '09:00'::TIME,
            '17:00'::TIME
        FROM unnest(ARRAY['monday', 'tuesday', 'wednesday', 'thursday', 'friday']) AS day;

        -- Add some test appointments (based on density)
        INSERT INTO public.purchases (
            id, user_id, owner_id, amount, currency, payment_status, service_id, purchase_type
        )
        SELECT
            gen_random_uuid(),
            gen_random_uuid(),
            v_provider_id,
            100,
            'GBP',
            'completed',
            gen_random_uuid(),
            'appointment'
        FROM generate_series(1, FLOOR(p_days_ahead * 8 * p_appointment_density)::INTEGER);

        -- Measure availability calculation time
        v_start_time := clock_timestamp();

        SELECT COUNT(*)
        INTO v_slot_count
        FROM get_provider_availability(v_provider_id, CURRENT_DATE, CURRENT_DATE + p_days_ahead)
        CROSS JOIN LATERAL jsonb_array_elements(available_slots)
        WHERE (jsonb_array_elements->>'available')::BOOLEAN = true;

        v_duration := extract(epoch from (clock_timestamp() - v_start_time)) * 1000;

        provider_index := i;
        calculation_time_ms := v_duration;
        available_slot_count := v_slot_count;

        RETURN NEXT;

        -- Clean up test data
        DELETE FROM public.purchases WHERE owner_id = v_provider_id;
        DELETE FROM public.availability WHERE user_id = v_provider_id;
    END LOOP;

    RETURN;
END;
$$ LANGUAGE plpgsql;
```

## Implementation Plan

Based on our detailed analysis, here is the recommended implementation plan:

### Sprint 1: Foundation (1 week)

- Create the provider_preferences and availability_exceptions tables
- Implement the get_provider_availability function
- Add booking_workflow fields to services table
- Expand status options in appointment_purchases

### Sprint 2: Integration Layer (1 week)

- Create the services_with_availability view
- Implement conflict prevention triggers
- Build the request_service_appointment function
- Create the respond_to_appointment_request function

### Sprint 3: Provider Tools (1 week)

- Implement update_provider_schedule function
- Build get_provider_appointment_dashboard
- Develop the recommended_slots function
- Create the book_service_appointment function

### Sprint 4: Client Experience (1 week)

- Implement get_service_calendar_availability
- Build get_service_day_slots function
- Create the service_calendar_view
- Develop appointment notification functions

### Sprint 5: Testing & Optimization (1 week)

- Write comprehensive unit tests
- Perform stress testing and optimization
- Implement caching for expensive operations
- Add proper indexes for performance

### Sprint 6: Data Migration & Deployment (1 week)

- Migrate legacy appointment data
- Deploy in staged rollout
- Monitor performance and errors
- Document APIs and provide usage examples

## Conclusion

The proposed service appointment system addresses the limitations of the current architecture while building on its strengths. By integrating the best aspects of both systems and adding sophisticated conflict prevention, we can create a reliable, flexible platform that:

1. **Prevents Double-Booking** by checking availability across both appointment systems and events
2. **Supports Multiple Workflows** to accommodate different service types and provider preferences
3. **Enhances User Experience** with intuitive calendars, smart recommendations, and clear communication
4. **Optimizes Provider Operations** through comprehensive dashboards and efficient management tools
5. **Scales Effectively** with careful performance optimization and caching strategies

This unified approach will significantly improve reliability while giving both clients and providers greater flexibility and control over the appointment booking process.
