# Service Appointment System Documentation

This document provides a comprehensive overview of the service appointment system, including database schema, functions, workflows, and integration specifications.

## Table of Contents

1. [Database Schema](#database-schema)
2. [Core Functions](#core-functions)
3. [Views](#views)
4. [End-to-End Workflows](#end-to-end-workflows)
5. [Integration Guide](#integration-guide)
6. [Interface Control Documents](#interface-control-documents)
7. [System Component Breakdown](#system-component-breakdown)
8. [Data Flow Diagrams](#data-flow-diagrams)

## Database Schema

### Core Tables

| Table                     | Description                    | Purpose                                                         | Key Fields                                                                       |
| ------------------------- | ------------------------------ | --------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| `services`                | Stores service information     | Central repository for all bookable service definitions         | `id`, `post_id`, `type`, `price`, `duration`, `booking_workflow`, `auto_confirm` |
| `appointment_purchases`   | Tracks service appointments    | Connects purchases to service appointments with status tracking | `id`, `purchase_id`, `service_id`, `appointment_date`, `duration`, `status`      |
| `purchases`               | Financial records for services | Tracks all financial transactions related to services           | `id`, `user_id`, `owner_id`, `amount`, `payment_status`, `purchase_type`         |
| `provider_preferences`    | Service provider settings      | Stores provider-specific settings for appointment handling      | `user_id`, `appointment_buffer_minutes`, `timezone`, `auto_confirm`              |
| `availability`            | Regular provider availability  | Defines recurring weekly availability patterns                  | `user_id`, `day`, `start_time`, `end_time`, `is_active`                          |
| `availability_exceptions` | One-time availability changes  | Manages date-specific availability overrides                    | `id`, `user_id`, `exception_date`, `is_available`, `start_time`, `end_time`      |

### Relationships

- **services** → **appointment_purchases**: One-to-many (one service can have many appointments)
- **purchases** → **appointment_purchases**: One-to-one (each appointment has one purchase record)
- **users** → **provider_preferences**: One-to-one (each provider has one preference record)
- **users** → **availability**: One-to-many (providers have multiple availability records)
- **users** → **availability_exceptions**: One-to-many (providers have multiple exception records)

### Appointment Status Values

| Status             | Description                          | Next Possible States                               | Triggering Actions                              |
| ------------------ | ------------------------------------ | -------------------------------------------------- | ----------------------------------------------- |
| `pending_approval` | Waiting for provider to approve      | `pending_payment`, `cancelled`                     | Provider approval, client/provider cancellation |
| `pending_payment`  | Approved, waiting for client payment | `confirmed`, `cancelled`                           | Payment completion, payment timeout             |
| `confirmed`        | Fully confirmed appointment          | `completed`, `cancelled`, `no_show`, `rescheduled` | Provider marking completion, reschedule action  |
| `cancelled`        | Cancelled appointment                | (Terminal state)                                   | N/A                                             |
| `completed`        | Completed appointment                | (Terminal state)                                   | N/A                                             |
| `no_show`          | Client didn't show up                | (Terminal state)                                   | N/A                                             |
| `rescheduled`      | Appointment time was changed         | `confirmed`, `cancelled`                           | Client acceptance of new time                   |

### Workflow Options

| Workflow       | Description                                   | Initial Status     | Payment Timing          | Provider Action Required         |
| -------------- | --------------------------------------------- | ------------------ | ----------------------- | -------------------------------- |
| `direct`       | Immediate booking (possibly with payment)     | `pending_payment`  | Before confirmation     | None if auto_confirm=true        |
| `pre-approval` | Provider must approve before payment          | `pending_approval` | After provider approval | Approval required                |
| `waitlist`     | Added to waitlist, provider manually confirms | `pending_approval` | After provider approval | Selection from waitlist required |

## Core Functions

### Appointment Booking

#### `request_service_appointment`

**Purpose**: Entry point for clients to request appointments based on service parameters.

**Parameters:**

- `p_service_id` (UUID): The service being booked
- `p_requested_date` (TIMESTAMP WITH TIME ZONE): Requested appointment time
- `p_duration` (INTEGER, optional): Duration in minutes, defaults to service duration
- `p_method` (TEXT, optional): 'video', 'in-person', etc., defaults to 'video'
- `p_service_type` (TEXT, optional): Type of service, defaults to 'consultation'
- `p_notes` (TEXT, optional): Client notes
- `p_client_id` (UUID, optional): Client ID, defaults to current user

**Returns:** JSONB with appointment details and next steps

**Detailed Flow:**

1. Validates service exists and is bookable
2. Retrieves provider settings and preferences
3. Checks if requested time slot is available:
   - Within provider's defined availability
   - Not conflicting with existing appointments
   - Respects buffer time between appointments
4. Determines initial status based on workflow:
   - `direct` + `auto_confirm=true` → `confirmed`
   - `direct` + `auto_confirm=false` → `pending_payment`
   - `pre-approval` → `pending_approval`
   - `waitlist` → `pending_approval`
5. Creates purchase record with appropriate status
6. Creates appointment record linked to purchase
7. Triggers notifications based on initial status
8. Returns result with appointment details, IDs and next steps

**Integration Points:**

- Frontend booking widget
- Calendar systems
- Email notification system
- Chat notification system

#### `respond_to_appointment_request`

**Purpose**: Allows providers to respond to appointment requests with various actions.

**Parameters:**

- `p_appointment_id` (UUID): Appointment to respond to
- `p_action` (TEXT): 'confirm', 'reject', 'suggest_alternative'
- `p_alternative_time` (TIMESTAMP WITH TIME ZONE, optional): Alternative time if suggesting
- `p_provider_notes` (TEXT, optional): Provider notes

**Returns:** JSONB with action result

**Detailed Flow:**

1. Validates appointment exists and user has provider permission
2. Verifies current status allows the requested action
3. Processes the response based on action:
   - 'confirm': Updates status to `pending_payment` or `confirmed` based on workflow
   - 'reject': Updates status to `cancelled` with reason
   - 'suggest_alternative': Creates new appointment option with suggested time
4. Updates appointment status and adds provider notes
5. Updates purchase record status if needed
6. Triggers appropriate notifications for client
7. Returns result with updated status and next steps

**Integration Points:**

- Provider dashboard
- Calendar systems
- Email notification system
- Chat notification system

### Availability Management

#### `get_provider_availability`

**Purpose**: Core function for retrieving and calculating a provider's available time slots.

**Parameters:**

- `p_provider_id` (UUID): Provider to check
- `p_start_date` (DATE): Start of range
- `p_end_date` (DATE): End of range

**Returns:** TABLE with dates and available slots as JSONB

**Detailed Flow:**

1. Retrieves provider preferences (timezone, buffer minutes)
2. Builds base availability from regular weekly schedule:
   - Maps day of week to date-specific slots
   - Applies start/end times for each weekday
3. Applies availability exceptions:
   - Removes dates marked unavailable
   - Overrides times for dates with exceptions
4. Retrieves existing appointments and events
5. Filters out slots with conflicts:
   - Existing appointments
   - Calendar events from integrated systems
   - Respects buffer time between appointments
6. Filters out past times
7. Formats results as time slots by date
8. Returns available slots organized by date

**Integration Points:**

- Booking calendar widget
- Provider availability settings
- External calendar systems

#### `get_service_calendar_availability`

**Purpose**: Provides calendar-friendly formatted availability data for frontend display.

**Parameters:**

- `p_service_id` (UUID): Service to check
- `p_days_ahead` (INTEGER, optional): Number of days to look ahead, defaults to 30
- `p_timezone` (TEXT, optional): Timezone override

**Returns:** JSONB with calendar-formatted availability

**Detailed Flow:**

1. Retrieves service provider information and service duration
2. Calculates date range based on days_ahead parameter
3. Calls `get_provider_availability` with calculated parameters
4. Processes results into calendar-friendly format:
   - Groups by date
   - Formats times according to service duration
   - Applies client timezone if provided
5. Calculates availability statistics:
   - Earliest available slot
   - Latest available slot
   - Total available slots
   - Days with availability
6. Returns consolidated data formatted for calendar display

**Integration Points:**

- Booking calendar widget
- Service display pages

### Appointment Notification System

#### `handle_appointment_request`

**Purpose**: Creates appointment records and initiates the notification workflow.

**Parameters:**

- `p_service_id` (UUID): Service ID
- `p_user_id` (UUID): Client user ID
- `p_owner_id` (UUID): Provider user ID
- `p_post_id` (UUID): Related post ID
- `p_appointment_date` (TIMESTAMP WITH TIME ZONE): Requested time
- `p_duration` (INTEGER): Duration in minutes
- `p_method` (TEXT, optional): Appointment method
- `p_message` (TEXT, optional): Request message

**Returns:** JSONB with appointment details

**Detailed Flow:**

1. Creates purchase record with appropriate status:
   - Sets initial amount based on service price
   - Sets status to `pending` or workflow-specific value
2. Creates appointment purchase record:
   - Links to purchase record
   - Sets appointment date and duration
   - Sets initial status based on workflow
3. Creates chat notification with appointment details:
   - Formats message for provider with request details
   - Includes quick action buttons (approve/reject)
4. Triggers email notification via pg_notify:
   - Sends event to notification queue
   - Includes appointment details for template
5. Returns comprehensive appointment details including IDs

**Integration Points:**

- Frontend booking form
- Chat system
- Email notification system

#### `approve_appointment_request`

**Purpose**: Processes provider approval and initiates payment flow if needed.

**Parameters:**

- `p_appointment_id` (UUID): Appointment to approve
- `p_price` (NUMERIC): Price for the service
- `p_message` (TEXT, optional): Message to client

**Returns:** JSONB with approval details

**Detailed Flow:**

1. Retrieves appointment and purchase details
2. Validates current status is `pending_approval`
3. Updates appointment status to `pending_payment`
4. Updates purchase with final price and metadata
5. Generates payment link with service details
6. Creates chat notification with:
   - Approval message
   - Payment link
   - Service details
7. Triggers email notification with payment instructions
8. Returns payment metadata and updated status

**Integration Points:**

- Provider dashboard
- Payment system
- Chat system
- Email notification system

#### `reschedule_appointment_request`

**Purpose**: Handles appointment rescheduling with appropriate notifications.

**Parameters:**

- `p_appointment_id` (UUID): Appointment to reschedule
- `p_new_date` (TIMESTAMP WITH TIME ZONE): New appointment time
- `p_duration` (INTEGER, optional): New duration
- `p_message` (TEXT, optional): Message to client

**Returns:** JSONB with rescheduling details

**Detailed Flow:**

1. Retrieves appointment and purchase details
2. Validates that rescheduling is allowed for current status
3. Verifies new time slot is available
4. Updates appointment date and status to `rescheduled`
5. Updates purchase record with new dates
6. Creates chat notification about reschedule:
   - Includes old and new times
   - Includes provider message
   - Action buttons for client to accept/reject
7. Triggers email notification with reschedule details
8. Returns updated appointment details

**Integration Points:**

- Provider dashboard
- Calendar systems
- Chat system
- Email notification system

#### `process_appointment_payment_confirmation`

**Purpose**: Updates appointment after payment and sends confirmation notifications.

**Parameters:**

- `p_purchase_id` (UUID): Purchase ID
- `p_payment_intent_id` (TEXT): Payment intent ID

**Returns:** JSONB with confirmation details

**Detailed Flow:**

1. Validates payment intent exists and matches purchase
2. Updates purchase status to `completed`
3. Updates appointment status to `confirmed`
4. Records payment details on purchase record
5. Creates chat notifications:
   - Client notification with confirmation details
   - Provider notification with booking details
6. Triggers email notifications:
   - Client confirmation email with appointment details
   - Provider booking notification with client details
7. Adds appointment to relevant calendars
8. Returns confirmation details with next steps

**Integration Points:**

- Payment system (Stripe)
- Calendar systems
- Chat system
- Email notification system

### Conflict Prevention

#### `check_schedule_conflicts`

**Purpose**: Ensures time slot integrity by checking for conflicts across all scheduling systems.

**Parameters:**

- `p_provider_id` (UUID): Provider to check
- `p_start_time` (TIMESTAMP WITH TIME ZONE): Start time
- `p_end_time` (TIMESTAMP WITH TIME ZONE): End time
- `p_exclude_appointment_id` (UUID, optional): Appointment to exclude

**Returns:** BOOLEAN indicating if conflicts exist

**Detailed Flow:**

1. Applies provider buffer time to start/end times
2. Checks appointment_purchases for conflicts:
   - Excludes specified appointment ID if provided
   - Only checks active appointments (not cancelled)
3. Checks legacy appointments for conflicts:
   - Ensures backward compatibility
4. Checks events system for conflicts:
   - Queries integrated calendar systems
   - Considers event types and priorities
5. Returns true if any conflicts found, false otherwise

**Integration Points:**

- Appointment booking system
- Legacy appointment systems
- Calendar integration systems

#### `prevent_double_booking`

**Purpose**: Database trigger to ensure scheduling integrity at the database level.

**Trigger on:** appointment_purchases, appointments
**Trigger when:** BEFORE INSERT OR UPDATE

**Detailed Flow:**

1. Extracts provider ID and time range from record
2. Skips check for terminal statuses (cancelled/completed)
3. Calls `check_schedule_conflicts` with parameters
4. Raises exception with specific error message if conflicts exist
5. Allows operation to proceed if no conflicts

**Integration Points:**

- Database layer
- Error handling systems

#### `lock_provider_schedule`

**Purpose**: Prevents race conditions when multiple bookings are attempted simultaneously.

**Parameters:**

- `p_provider_id` (UUID): Provider to lock

**Returns:** BIGINT lock key

**Detailed Flow:**

1. Converts UUID to stable integer lock key
2. Attempts to acquire advisory lock in database
3. Uses exponential backoff strategy:
   - Starts with 50ms wait
   - Doubles wait time on each attempt
   - Maximum 5 seconds total wait time
4. Returns lock key if successful
5. Raises exception if lock cannot be acquired

**Integration Points:**

- Concurrent booking systems
- High-traffic scenarios

## Views

### `service_details_view`

**Purpose**: Provides a comprehensive single-source-of-truth for service information display.

**Key fields:**

- Base service information (id, title, price, etc.)
- Location details as JSONB
- Creator profile as JSONB
- Tags as array

**Usage Scenarios:**

- Service listing pages
- Service detail pages
- Service search results
- Provider dashboards

### `service_appointments_view`

**Purpose**: Gives providers a consolidated view of appointments with client information.

**Key fields:**

- Appointment details
- Client information as JSONB
- Status flags (is_future, is_confirmed, etc.)

**Usage Scenarios:**

- Provider appointment dashboard
- Booking management interfaces
- Revenue reporting

### `user_appointments_view`

**Purpose**: Tailored view for clients to see their booked appointments.

**Key fields:**

- Appointment details
- Service and provider information
- Payment and status information

**Usage Scenarios:**

- Client dashboard
- Upcoming appointments display
- Appointment history

### `comprehensive_services_view`

**Purpose**: Aggregates appointment data with services for high-level overview.

**Key fields:**

- All service_details_view fields
- Appointments array (confirmed/pending)
- Future appointments array
- Past appointments array
- Availability statistics

**Usage Scenarios:**

- Admin dashboards
- Service analytics
- Provider performance reporting

### `services_with_availability`

**Purpose**: Optimized view for service discovery with availability filtering.

**Key fields:**

- All service fields
- has_availability flag

**Usage Scenarios:**

- Service search with availability filter
- "Book now" quick filters
- Service marketplace display

## End-to-End Workflows

### 1. Client Requests Appointment

**Detailed Workflow:**

1. **Booking Initiation**

   - Client views service details page
   - Selects "Book Appointment" button
   - Calendar widget loads showing available times
   - Client selects date/time and enters request details

2. **Submission Processing**

   - Frontend calls `request_service_appointment`
   - System validates time slot availability
   - System determines workflow path and initial status
   - Creates purchase and appointment records
   - Returns appointment reference and next steps to client

3. **Notification Flow**

   - `handle_appointment_request` creates chat notification
   - System generates chat message to provider
   - Database trigger calls `notify_appointment_status_change`
   - Event processor generates and sends email notification
   - Provider receives notifications via email and chat

4. **Status Path Variations**

   **Pre-approval workflow:**

   - Initial status: `pending_approval`
   - Provider dashboard shows pending request
   - Provider approves: status → `pending_payment`
   - Client receives payment link
   - Payment completes: status → `confirmed`

   **Direct workflow with auto_confirm:**

   - Initial status: `confirmed`
   - Payment processed immediately
   - Both parties receive confirmation notifications

   **Direct workflow without auto_confirm:**

   - Initial status: `pending_payment`
   - Client receives payment link immediately
   - After payment: status → `confirmed`

   **Waitlist workflow:**

   - Initial status: `pending_approval`
   - Added to provider's waitlist queue
   - Provider selects from waitlist: status → `pending_payment`
   - Remainder same as pre-approval

5. **Client Experience**
   - Receives confirmation screen with next steps
   - For pre-approval: "Request sent, awaiting provider approval"
   - For direct payment: "Please complete payment to confirm"
   - For auto-confirm: "Appointment confirmed!"
   - Email notification with details
   - Dashboard shows appointment with status

### 2. Provider Approves Appointment

**Detailed Workflow:**

1. **Provider Notification**

   - Provider receives chat notification
   - Provider receives email notification
   - Provider dashboard shows pending appointment requests
   - Request details include client info, requested time, service details

2. **Approval Action**

   - Provider reviews request details
   - Decides to approve, reject, or suggest alternative time
   - For approval: Provider clicks "Approve" button
   - Provider may adjust price or add notes

3. **System Processing**

   - Provider dashboard calls `approve_appointment_request`
   - System updates status to `pending_payment`
   - Sets final price on purchase record
   - Generates unique payment link with service details
   - Updates appointment metadata

4. **Client Notification**

   - Creates chat notification with payment link
   - Formats message with appointment details and payment button
   - Triggers email notification with payment link
   - Client receives notifications via chat and email
   - Client dashboard shows updated status

5. **Provider Experience**
   - Dashboard shows status change to "Awaiting Payment"
   - Provider can view payment status
   - Provider can send reminders if payment delayed

### 3. Provider Reschedules Appointment

**Detailed Workflow:**

1. **Reschedule Initiation**

   - Provider views appointment details
   - Selects "Reschedule" option
   - Calendar shows available alternative times
   - Provider selects new time and adds explanation note

2. **System Processing**

   - Provider dashboard calls `reschedule_appointment_request`
   - System validates new time slot availability
   - Updates appointment date in appointment record
   - Updates related purchase record dates
   - Sets status to `rescheduled`
   - Records provider's explanation note

3. **Client Notification**

   - Creates chat notification about reschedule
   - Formats message with old and new times
   - Includes provider's explanation
   - Adds accept/reject buttons for client
   - Triggers email notification with reschedule details
   - Client receives notifications via chat and email

4. **Client Response Options**

   - Accept: Status changes to `confirmed` for new time
   - Reject: Opens chat to negotiate alternative
   - Request refund: Initiates cancellation process

5. **Calendar Updates**
   - Removes original time slot from provider calendar
   - Adds new time slot to provider calendar
   - Updates client calendar invitation with new time

### 4. Client Makes Payment

**Detailed Workflow:**

1. **Payment Initiation**

   - Client receives payment link via chat or email
   - Client clicks link which opens payment page
   - Payment page shows appointment details and price
   - Client enters payment information

2. **Payment Processing**

   - Client submits payment form to Stripe
   - Stripe processes payment and creates payment intent
   - Stripe calls webhook on successful payment
   - Backend webhook handler calls `processAppointmentBooking`
   - `process_appointment_payment_confirmation` processes the payment

3. **Record Updates**

   - Updates purchase status to `completed`
   - Records payment details (amount, payment method, etc.)
   - Updates appointment status to `confirmed`
   - Sets appointment metadata with payment information

4. **Confirmation Notifications**

   - Creates chat notifications for both parties
   - Client notification focuses on appointment details
   - Provider notification focuses on booking alert
   - Triggers email confirmations to both parties
   - Updates calendars with confirmed appointment

5. **Post-Payment Experience**
   - Client dashboard shows confirmed appointment
   - Provider dashboard shows confirmed booking
   - Both receive calendar invitations if enabled
   - Appointment appears in service appointment history

### 5. Appointment Completion

**Detailed Workflow:**

1. **Day-of Notifications**

   - System sends appointment reminders:
     - 24 hours before appointment
     - 1 hour before appointment
   - Both client and provider receive reminders
   - Reminders include joining instructions if virtual

2. **Appointment Execution**

   - Provider and client join appointment (virtual or in-person)
   - Provider can mark as "in progress" when started
   - System tracks actual start time if recorded

3. **Completion Marking**

   - Provider marks appointment as `completed` after service
   - System updates appointment status
   - Records actual duration if tracked
   - Triggers post-appointment workflows

4. **Post-Appointment Flow**

   - Client receives feedback request
   - Provider can add notes to appointment record
   - System may trigger follow-up booking suggestions
   - Financial records finalized for reporting

5. **No-show Handling**
   - If client doesn't appear, provider marks as `no_show`
   - System may apply cancellation fee based on policy
   - Provider's schedule is freed for other bookings
   - No-show is recorded in client history

## Integration Guide

### Frontend Components Required

1. **Service Booking Widget**

   **Purpose**: Primary entry point for clients to book appointments.

   **Key Features:**

   - Interactive calendar with available slots
   - Time slot selection with timezone support
   - Form for additional request details
   - Booking confirmation display

   **API Integration:**

   - GET `/api/services/{id}/availability` to fetch calendar data
   - GET `/api/providers/{id}/timezone` to handle timezone conversion
   - POST `/api/appointments/request` to submit booking

   **User Experience Flow:**

   1. Load service details
   2. Display calendar with available dates
   3. User selects date to see available time slots
   4. User selects time slot and enters details
   5. User submits booking request
   6. Display confirmation or next steps

2. **Provider Dashboard**

   **Purpose**: Central management interface for providers to handle appointments.

   **Key Features:**

   - List of pending appointment requests
   - Approve/Reject/Reschedule functions
   - Calendar view of confirmed bookings
   - Availability management tools

   **API Integration:**

   - GET `/api/appointments/provider/{id}` to fetch appointments
   - POST `/api/appointments/approve` for approval
   - POST `/api/appointments/reject` for rejection
   - POST `/api/appointments/reschedule` for rescheduling
   - PUT `/api/providers/{id}/availability` to update availability

   **User Experience Flow:**

   1. Dashboard overview with pending counts
   2. List of pending requests with client info
   3. Provider reviews and takes action
   4. Calendar view updates with changes
   5. Provider receives confirmation

3. **Client Dashboard**

   **Purpose**: Interface for clients to manage their appointments.

   **Key Features:**

   - List of appointments with status indicators
   - Payment links for pending payments
   - Appointment details view
   - Reschedule/cancel request options

   **API Integration:**

   - GET `/api/appointments/client/{id}` to fetch appointments
   - GET `/api/appointments/{id}/details` for details
   - POST `/api/appointments/cancel-request` for cancellation
   - POST `/api/payments/process` for payment handling

   **User Experience Flow:**

   1. Dashboard shows appointment status summary
   2. List of appointments by status
   3. Client selects appointment for details
   4. Client takes action (pay, cancel, etc.)
   5. Status updates reflect changes

4. **Chat Integration**

   **Purpose**: Facilitates communication about appointments.

   **Key Features:**

   - Display appointment notification cards
   - Interactive buttons for quick actions
   - Payment link integration
   - Appointment details formatting

   **API Integration:**

   - WebSocket for real-time chat updates
   - GET `/api/chat/appointment/{id}` for appointment-specific messages
   - POST `/api/chat/appointment/{id}/message` to send messages

   **User Experience Flow:**

   1. User receives notification in chat
   2. Appointment card displays with details
   3. User can take actions directly from chat
   4. Chat history maintains record of interactions

5. **Email Templates**

   **Purpose**: Provide consistent notification experience via email.

   **Key Email Types:**

   - Appointment request notification
   - Approval notification with payment link
   - Rescheduling notification
   - Confirmation notification
   - Reminder notification

   **Template Variables:**

   - `{appointmentDate}`: Formatted appointment date
   - `{appointmentTime}`: Formatted appointment time
   - `{serviceName}`: Name of the service
   - `{providerName}`: Name of the provider
   - `{clientName}`: Name of the client
   - `{paymentLink}`: Payment URL
   - `{actionButtons}`: HTML for action buttons

   **Email Delivery Flow:**

   1. System triggers notification event
   2. Email service receives event with parameters
   3. Template is populated with variables
   4. Email is sent to recipient
   5. Email tracking records delivery/open

### API Endpoints Required

1. **/api/appointments/request**

   **Purpose**: Creates new appointment requests.

   **Method**: POST

   **Parameters:**

   - `serviceId`: UUID of service
   - `requestedDate`: ISO timestamp
   - `duration`: Optional duration in minutes
   - `method`: Optional meeting method
   - `notes`: Optional client notes

   **Response:**

   - `appointmentId`: UUID of created appointment
   - `status`: Initial status
   - `nextSteps`: Action description for client
   - `paymentLink`: Only if immediate payment needed

   **Error Handling:**

   - 400: Invalid parameters
   - 404: Service not found
   - 409: Time slot unavailable
   - 500: Server error

2. **/api/appointments/approve**

   **Purpose**: Allows providers to approve appointment requests.

   **Method**: POST

   **Parameters:**

   - `appointmentId`: UUID of appointment
   - `price`: Final price for service
   - `message`: Optional message to client

   **Response:**

   - `status`: Updated status
   - `paymentLink`: Payment URL for client
   - `nextSteps`: Action description

   **Error Handling:**

   - 400: Invalid parameters
   - 403: Unauthorized (not the provider)
   - 404: Appointment not found
   - 409: Invalid status transition
   - 500: Server error

3. **/api/appointments/reschedule**

   **Purpose**: Handles appointment rescheduling.

   **Method**: POST

   **Parameters:**

   - `appointmentId`: UUID of appointment
   - `newDate`: ISO timestamp of new date
   - `duration`: Optional new duration
   - `message`: Optional explanation message

   **Response:**

   - `status`: Updated status
   - `originalDate`: Old appointment date
   - `newDate`: New appointment date
   - `nextSteps`: Action description

   **Error Handling:**

   - 400: Invalid parameters
   - 403: Unauthorized (not the provider)
   - 404: Appointment not found
   - 409: New time slot unavailable
   - 500: Server error

4. **/api/stripe/webhook**

   **Purpose**: Processes Stripe payment webhooks.

   **Method**: POST

   **Parameters:**

   - Stripe webhook payload

   **Processing:**

   - Verifies Stripe signature
   - Extracts payment intent ID
   - Matches to purchase record
   - Calls `process_appointment_payment_confirmation`

   **Response:**

   - 200: Success acknowledgment

   **Error Handling:**

   - 400: Invalid webhook payload
   - 409: Payment already processed
   - 500: Processing error

5. **/api/appointment-notifications**

   **Purpose**: Processes email notifications.

   **Method**: POST

   **Parameters:**

   - `type`: Notification type
   - `appointmentId`: UUID of appointment
   - `recipientId`: UUID of recipient
   - `templateData`: Template variables

   **Processing:**

   - Retrieves recipient email
   - Selects appropriate template
   - Populates template with data
   - Sends email via provider

   **Response:**

   - `messageId`: Email delivery ID
   - `status`: Delivery status

   **Error Handling:**

   - 400: Invalid parameters
   - 404: Recipient not found
   - 500: Delivery error

### Payment Flow

1. **Payment Initiation**

   - Provider approves appointment and sets price
   - System generates Stripe checkout session
   - Payment link includes:
     - Appointment ID as metadata
     - Service name and details
     - Price and currency
     - Success/cancel redirect URLs

2. **Checkout Process**

   - Client clicks payment link in chat/email
   - Stripe checkout page loads with appointment details
   - Client enters payment information
   - Stripe processes payment and creates payment intent
   - On success, redirects to confirmation page

3. **Payment Confirmation**

   - Stripe sends webhook with payment event
   - System receives webhook at `/api/stripe/webhook`
   - Webhook handler verifies signature and event type
   - System matches payment intent to appointment
   - Calls `process_appointment_payment_confirmation`

4. **Post-Payment Processing**

   - System updates purchase status to `completed`
   - Updates appointment status to `confirmed`
   - Records payment details (amount, method, fees)
   - Generates receipt number and confirmation code
   - Updates financial records for reporting

5. **Confirmation Notifications**
   - System creates chat notifications for both parties
   - Sends email confirmations with appointment details
   - Includes calendar attachments (ICS files)
   - Updates dashboards for both user types
   - Schedules reminder notifications

## Interface Control Documents

### Appointment Data Schema

```
{
  "id": "uuid",
  "serviceId": "uuid",
  "purchaseId": "uuid",
  "clientId": "uuid",
  "providerId": "uuid",
  "status": "string",
  "appointmentDate": "ISO8601 timestamp",
  "duration": "number (minutes)",
  "method": "string",
  "notes": {
    "client": "string",
    "provider": "string"
  },
  "price": "number",
  "paymentStatus": "string",
  "createdAt": "ISO8601 timestamp",
  "updatedAt": "ISO8601 timestamp",
  "metadata": {
    // Additional service-specific fields
  }
}
```

### Notification Event Schema

```
{
  "type": "string", // appointment.request, appointment.approve, etc.
  "appointmentId": "uuid",
  "recipientId": "uuid",
  "recipientType": "string", // client, provider
  "data": {
    // Event-specific data
  },
  "timestamp": "ISO8601 timestamp"
}
```

### Payment Webhook Schema

```
{
  "type": "payment_intent.succeeded",
  "data": {
    "object": {
      "id": "pi_...", // payment intent ID
      "metadata": {
        "appointmentId": "uuid",
        "purchaseId": "uuid"
      },
      "amount": "number",
      "currency": "string",
      "status": "string"
    }
  }
}
```

### Availability Data Schema

```
{
  "providerId": "uuid",
  "timezone": "string",
  "dates": [
    {
      "date": "YYYY-MM-DD",
      "slots": [
        {
          "start": "ISO8601 timestamp",
          "end": "ISO8601 timestamp",
          "available": "boolean"
        }
      ]
    }
  ],
  "statistics": {
    "earliestAvailable": "ISO8601 timestamp",
    "totalSlots": "number",
    "availableDays": "number"
  }
}
```

## System Component Breakdown

### Core System Components

1. **Appointment Engine**

   - **Purpose**: Central component handling appointment creation, updates, and status transitions
   - **Key Functions**: `request_service_appointment`, `respond_to_appointment_request`
   - **Integration Points**: User interface, payment system, notification system
   - **Data Flow**: Receives booking requests, updates database, triggers notifications

2. **Availability Manager**

   - **Purpose**: Calculates and manages provider availability
   - **Key Functions**: `get_provider_availability`, `get_service_calendar_availability`
   - **Integration Points**: Calendar systems, booking interface
   - **Data Flow**: Processes provider schedules, exclusions, and existing appointments

3. **Notification Dispatcher**

   - **Purpose**: Handles all appointment-related notifications
   - **Key Functions**: Email notifications, chat notifications, calendar invites
   - **Integration Points**: Email service, chat system, calendar system
   - **Data Flow**: Receives event triggers, formats notifications, dispatches to recipients

4. **Payment Processor**

   - **Purpose**: Manages payment lifecycle for appointments
   - **Key Functions**: Generate payment links, process confirmations, handle refunds
   - **Integration Points**: Stripe, financial reporting system
   - **Data Flow**: Receives payment requests, communicates with Stripe, updates appointment records

5. **Calendar Integration**
   - **Purpose**: Syncs appointments with calendar systems
   - **Key Functions**: Create calendar events, handle updates, process RSVPs
   - **Integration Points**: Google Calendar, Outlook, iCalendar
   - **Data Flow**: Receives appointment changes, updates external calendars

### Support Components

1. **Reporting Engine**

   - **Purpose**: Generates reports on appointment metrics
   - **Key Functions**: Usage statistics, revenue reports, provider performance
   - **Integration Points**: Dashboard UI, financial systems
   - **Data Flow**: Aggregates appointment data, generates insights

2. **Conflict Resolution System**

   - **Purpose**: Prevents and handles scheduling conflicts
   - **Key Functions**: `check_schedule_conflicts`, `prevent_double_booking`
   - **Integration Points**: Booking engine, calendar systems
   - **Data Flow**: Validates time slot requests, prevents overlapping bookings

3. **Admin Management Interface**
   - **Purpose**: Provides administrative control and oversight
   - **Key Functions**: Override statuses, handle special cases, system configuration
   - **Integration Points**: Admin UI, all other components
   - **Data Flow**: Receives admin commands, affects system behavior

## Data Flow Diagrams

### Appointment Booking Flow

```
Client → Booking Widget → Appointment Engine → Database
   ↑                           ↓
   |                    Notification Dispatcher
   ↓                           ↓
Provider Dashboard ← -------- Email/Chat
```

### Payment Processing Flow

```
Client → Payment Link → Stripe → Webhook Handler → Payment Processor
                                        ↓
                                    Database
                                        ↓
                         Notification Dispatcher
                                        ↓
                               Email/Chat/Calendar
```

### Availability Calculation Flow

```
Provider Settings → Availability Manager → Database
       ↑                    ↓
  Admin Updates     Calendar Integration
       ↑                    ↓
Provider Dashboard    Booking Widget
```

### Appointment Status Lifecycle

```
pending_approval → pending_payment → confirmed → completed
       ↓                 ↓              ↓           ↑
    cancelled        cancelled      rescheduled     |
                                        ↓           |
                                    confirmed → no_show
```
