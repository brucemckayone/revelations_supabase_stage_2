# Integration Tests Setup Guide

## Quick Start

### 1. Install Dependencies

```bash
cd integration-tests
npm install
```

### 2. Environment Configuration

Create a `.env` file in the `integration-tests` directory:

```bash
# Copy your Supabase credentials here
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Optional: Enable verbose logging
VERBOSE_LOGGING=false
```

### 3. Run Tests

```bash
# Run all tests
npm test

# Run specific feature tests
npm run test:credits
npm run test:packages
npm run test:subscriptions

# Run with verbose logging
npm run test:verbose

# Clean up test data
npm run cleanup
```

## Current Implementation Status

### ✅ Completed

- **Infrastructure**: Database connection, test utilities, cleanup system
- **Credit System Tests**: Complete testing of `can_book_event_with_credits()` and `book_event_with_credits()` functions
  - Credit availability checking
  - Event booking with credits
  - FIFO credit deduction logic
  - Insufficient credits handling
  - Multiple event bookings
  - Usage tracking and audit trails

### 🚧 In Progress

- **Universal Packages Tests**: Package creation, purchase simulation, configuration
- **Subscription Billing Tests**: Recurring payments, credit refresh, billing cycles
- **Event Booking Tests**: Direct event purchases, ticket management
- **Webhook Processing Tests**: Payment webhook simulation, error handling
- **Error Handling Tests**: Edge cases, concurrent booking conflicts

## Test Features Overview

### Credit System Tests (`npm run test:credits`)

Tests the core credit booking functionality that enables users to book events using package credits.

**Key Test Scenarios:**

- ✅ Credit availability validation
- ✅ Successful credit-based booking
- ✅ FIFO credit deduction (oldest first)
- ✅ Insufficient credits error handling
- ✅ Multiple event bookings
- ✅ Usage tracking and audit

### Universal Packages Tests (`npm run test:packages`)

Tests package creation, configuration, and purchase processing.

**Planned Test Scenarios:**

- Package creation with event access configuration
- Package purchase simulation
- Credit allocation and management
- Recurring vs one-time packages
- Package expiration handling

### Subscription Billing Tests (`npm run test:subscriptions`)

Tests recurring billing and subscription management.

**Planned Test Scenarios:**

- Monthly billing cycle processing
- Credit refresh automation
- Failed payment handling
- Subscription status management
- Invoice processing functions

### Event Booking Tests (`npm run test:events`)

Tests direct event purchase flows and ticket management.

**Planned Test Scenarios:**

- Direct event ticket purchases
- Ticket availability and capacity
- Event date management
- Booking confirmation codes
- Multi-attendee support

### Webhook Processing Tests (`npm run test:webhooks`)

Tests payment webhook simulation and processing.

**Planned Test Scenarios:**

- Payment intent success processing
- Subscription event handling
- Invoice payment processing
- Error handling and retries
- Idempotency verification

### Error Handling Tests (`npm run test:errors`)

Tests edge cases and error scenarios.

**Planned Test Scenarios:**

- Concurrent booking conflicts
- Database constraint violations
- Payment failure recovery
- Invalid data handling
- System resilience testing

## Test Data Management

### Principles

- All test data uses `TEST_` prefix for easy identification
- Automatic cleanup after each test run
- No interference with real user data
- Uses real user IDs from seed data for integration testing

### Known Test Users

- **Creator**: `a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11`
- **Test Users**: Selected from existing auth.users (excluding creator)

### Data Lifecycle

1. **Setup**: Create test packages, events, purchases
2. **Execute**: Run test scenarios with real function calls
3. **Assert**: Verify expected database state and function outputs
4. **Cleanup**: Automatically remove all test data

## Troubleshooting

### Common Issues

**Database Connection Failed**

- Verify your Supabase URL and service role key
- Check network connectivity
- Ensure service role key has necessary permissions

**Tests Failing with Permission Errors**

- Make sure you're using the service role key, not the anon key
- Verify RLS policies allow service role access

**Test Data Not Cleaning Up**

- Run `npm run cleanup` manually
- Check if test data uses `TEST_` prefix consistently
- Verify foreign key constraints aren't preventing deletion

### Debugging

**Enable Verbose Logging**

```bash
npm run test:verbose
```

**Run Single Feature Test**

```bash
npm run test:credits
```

**Check Database State**
Connect to your Supabase database and check for records with `TEST_` prefix:

```sql
SELECT 'events' as table_name, count(*) as count FROM events WHERE title LIKE 'TEST_%'
UNION ALL
SELECT 'universal_packages', count(*) FROM universal_packages WHERE name LIKE 'TEST_%'
UNION ALL
SELECT 'purchases', count(*) FROM purchases WHERE payment_intent_id LIKE 'pi_test_%';
```

## Next Steps

1. **Implement Remaining Tests**: Add universal packages, subscription billing, and other feature tests
2. **Performance Testing**: Add load testing for concurrent bookings
3. **Integration with CI/CD**: Set up automated testing pipeline
4. **Frontend Integration**: Create mock API endpoints for frontend testing
5. **Documentation**: Expand test documentation and examples

## Contributing

When adding new tests:

1. Follow the existing test structure in `features/`
2. Use the test helpers from `utils/test-helpers.js`
3. Ensure proper cleanup of test data
4. Add comprehensive assertions
5. Update this documentation
