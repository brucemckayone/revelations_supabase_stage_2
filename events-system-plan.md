# Events System Integration with New Purchase System

## Overview

This document outlines the comprehensive event system integration with the new centralized purchase system. The solution involves creating views and functions that connect the existing event tables with the new purchase system, enabling a seamless experience for users browsing and booking events.

## Key Components

### 1. Database Views

We've created a layered set of views to provide complete event information:

1. **event_details_view**: Base view with core event information

   - Combines event, post, location, and room data
   - Structures location and room information as JSONB

2. **event_dates_view**: View for event dates with availability information

   - Includes is_future and is_fully_booked flags
   - Calculates current attendees from event_bookings

3. **event_tickets_view**: View for tickets with availability information

   - Calculates available_quantity based on bookings
   - Includes is_sold_out flag

4. **comprehensive_events_view**: Main view combining all event information
   - Aggregates dates, tickets, and tags as JSONB arrays
   - Calculates next_available_date and min_price
   - Provides all data needed for event listing and detail pages

### 2. Public Functions

#### Event Listing and Details

1. **get_upcoming_events**: Function to retrieve events for the events page

   - Supports filtering by event type, distance, creator, tags, etc.
   - Includes location-based sorting
   - Provides pagination support

2. **get_enhanced_event_details**: Function to get complete event details by slug
   - Returns a comprehensive JSONB object with all event data
   - Includes location, dates, tickets, and availability information

#### Booking System

1. **book_event_ticket**: Function to book an event ticket

   - Creates purchase record in the new purchase system
   - Creates event_booking record linking to the purchase
   - Performs validation checks (ticket availability, date validity)
   - Generates ticket code

2. **update_booking_status**: Function to update booking status

   - Updates both purchase and event_booking records
   - Handles payment status and booking status synchronization
   - Includes permission checks

3. **get_user_event_bookings**: Function to retrieve a user's ticket bookings
   - Returns comprehensive ticket information
   - Supports filtering by status (upcoming, past, cancelled)
   - Includes event, ticket, and payment details

## Integration with Purchase System

The new system connects the existing events tables with the new purchase system:

1. **Original Event System**:

   - events: Main event information linked to posts
   - event_dates: Event occurrence dates
   - tickets: Ticket types for each event

2. **New Purchase System**:

   - purchases: Central table for all purchases
   - event_bookings: Links purchases to events, tickets, and dates

3. **Integration Points**:
   - The new views join these tables to provide availability information
   - The booking function creates records in both systems
   - All money handling is done through the purchases table

## Usage Examples

### Event Listing Page

```sql
-- Get upcoming events near the user
SELECT * FROM get_upcoming_events(
    user_lat => 51.5074,
    user_lon => -0.1278,
    distance_limit => 50,
    page_size => 12,
    page_number => 0
);
```

### Event Details Page

```sql
-- Get complete event details by slug
SELECT * FROM get_enhanced_event_details('mindfulness-workshop-2025');
```

### Book a Ticket

```sql
-- Book an event ticket
SELECT book_event_ticket(
    p_event_id => '3fa85f64-5717-4562-b3fc-2c963f66afa6',
    p_ticket_id => '8c3a2e18-4f0a-4b5c-9b5d-3a8e6f9c7d1b',
    p_date_id => 'f7a85f64-5717-4562-b3fc-2c963f66afa6',
    p_quantity => 2,
    p_is_virtual => true,
    p_payment_intent_id => 'pi_3OrZ1yCZ6qsJgndV0MetsFxG'
);
```

### Update Booking Status

```sql
-- Update booking status after payment
SELECT update_booking_status(
    p_purchase_id => '3fa85f64-5717-4562-b3fc-2c963f66afa6',
    p_payment_status => 'completed'
);
```

### View User's Bookings

```sql
-- Get user's upcoming event bookings
SELECT * FROM get_user_event_bookings('upcoming');
```

## Implementation Notes

1. The design considers both online and in-person events
2. All booking operations are idempotent and validate availability
3. Proper error handling ensures clear error messages
4. Row-level security is maintained from the purchase system
5. The system is designed to handle high concurrency
