# Integration Tests Debugging Guide

## Quick Start

### 🚀 Start Debugging Immediately

```bash
# Debug all events tests with VS Code
npm run debug:events

# Debug specific test with Chrome DevTools
npm run debug:capacity  # Event capacity tests
npm run debug:booking   # Event booking tests
npm run debug:credits   # Universal package credits tests

# Debug cleanup system
npm run debug:cleanup
```

### 🔍 Chrome DevTools Debugging

1. Run any debug command (e.g., `npm run debug:capacity`)
2. Open Chrome and go to `chrome://inspect`
3. Click "Inspect" next to your Node.js target
4. Set breakpoints and step through code

## Debugging Methods

### 1. VS Code Debugging (Recommended)

**Setup:**

- The `.vscode/launch.json` is already configured
- Open the file you want to debug
- Press `F5` or go to Run & Debug panel
- Choose your debug configuration

**Available Configurations:**

- `Debug All Tests` - Run all integration tests
- `Debug Events Tests` - Run all events-related tests
- `Debug Event Capacity Tests` - Focus on capacity/availability tests
- `Debug Event Booking Tests` - Focus on booking/purchase tests
- `Debug Event Credits Tests` - Focus on universal package integration
- `Debug Cleanup System` - Debug the improved cleanup system
- `Debug Current Test File` - Debug whatever file is currently open

### 2. Chrome DevTools Debugging

```bash
# Start with breakpoint at beginning
npm run debug:capacity

# Or use Node.js inspector directly
node --inspect-brk debug-single-test.js event-capacity
```

### 3. Command Line Debugging

```bash
# Single test with detailed output
node debug-single-test.js event-capacity

# With additional debugging info
NODE_ENV=debug node debug-single-test.js event-booking

# Force cleanup debugging
node --inspect-brk force-cleanup-all.js --force
```

## Debugging Utilities

### Built-in Debug Helpers

Import debug utilities in your test files:

```javascript
import debug from "../../../shared/utilities/debug-utils.js";

// Set a debug breakpoint with context
debug.debugBreakpoint("Before event creation", { eventData });

// Inspect database state
await debug.inspectDatabaseState(["events", "tickets", "event_bookings"]);

// Time operations
const timer = new debug.DebugTimer("Event Creation");
// ... do work ...
timer.checkpoint("Created event");
// ... more work ...
timer.end();

// Trace function execution
const tracedFunction = debug.traceFunction(myFunction, "My Function Name");

// Debug Supabase queries
const result = await debug.debugQuery(
  supabase.from("events").select("*").eq("id", eventId),
  "Get Event Details"
);

// Create data snapshot
await debug.createTestDataSnapshot("After event booking");
```

### Manual Debugging Statements

Add these anywhere in your test code:

```javascript
// Simple breakpoint
debugger;

// Inspect variables
console.log("🔍 Event data:", { event, tickets, dates });

// Database state check
const { count } = await supabase
  .from("event_bookings")
  .select("*", { count: "exact", head: true });
console.log(`📊 Current bookings: ${count}`);

// Memory usage
const used = process.memoryUsage();
console.log("🧠 Memory:", Math.round(used.heapUsed / 1024 / 1024) + " MB");
```

## Common Debugging Scenarios

### 🎫 Event Booking Issues

```bash
# Debug booking flow
npm run debug:booking

# Focus on specific booking issue
node debug-single-test.js event-booking
```

**Debugging tips:**

- Set breakpoints in `createTestEventPurchase()`
- Check event/ticket/date existence
- Validate purchase parameters
- Inspect booking status transitions

### 📊 Capacity & Availability Issues

```bash
# Debug capacity calculations
npm run debug:capacity
```

**Debugging tips:**

- Breakpoint in capacity validation logic
- Check `event_tickets_view` calculations
- Verify sold-out detection
- Inspect overbooking prevention

### 💳 Universal Package Credits Issues

```bash
# Debug credit booking flow
npm run debug:credits
```

**Debugging tips:**

- Verify package purchase existence
- Check credit balance calculations
- Inspect credit deduction logic
- Validate package expiration

### 🧹 Cleanup Issues

```bash
# Debug cleanup system
npm run debug:cleanup

# Debug force cleanup
node --inspect-brk force-cleanup-all.js --force
```

**Debugging tips:**

- Check tracked records in fixtures
- Verify cleanup order
- Inspect constraint violations
- Monitor foreign key dependencies

## Step-by-Step Debugging Example

### Debugging a Failing Event Booking Test

1. **Start debugging:**

   ```bash
   npm run debug:booking
   ```

2. **In Chrome DevTools:**

   - Set breakpoint in `createTestEventPurchase()`
   - Step through parameter validation
   - Check database queries

3. **Add debug statements:**

   ```javascript
   // In your test file
   import debug from "../../../shared/utilities/debug-utils.js";

   // Before the failing operation
   await debug.inspectDatabaseState(['events', 'tickets']);
   debug.debugBreakpoint("Before purchase", purchaseData);

   // After the operation
   const result = await fixtures.createTestEventPurchase(...);
   debug.debugBreakpoint("After purchase", result);
   ```

4. **Inspect specific data:**

   ```javascript
   // Check event existence
   const { data: event } = await supabase
     .from("events")
     .select("*")
     .eq("id", eventId)
     .single();
   console.log("🎯 Event:", event);

   // Check ticket availability
   const { data: ticket } = await supabase
     .from("event_tickets_view")
     .select("*")
     .eq("ticket_id", ticketId)
     .single();
   console.log("🎫 Ticket availability:", ticket);
   ```

## Debugging Best Practices

### 🎯 Effective Debugging

1. **Use descriptive breakpoints:**

   ```javascript
   debug.debugBreakpoint("Before capacity check", {
     ticketId,
     requestedQuantity,
     availableQuantity,
   });
   ```

2. **Time operations to find bottlenecks:**

   ```javascript
   const timer = new debug.DebugTimer("Event Creation");
   timer.checkpoint("Created post");
   timer.checkpoint("Created event");
   timer.checkpoint("Created tickets");
   timer.end();
   ```

3. **Trace function calls:**

   ```javascript
   const tracedCreateEvent = debug.traceFunction(
     fixtures.createTestEvent,
     "Create Test Event"
   );
   ```

4. **Snapshot data at key points:**
   ```javascript
   await debug.createTestDataSnapshot("Before booking");
   // ... perform booking ...
   await debug.createTestDataSnapshot("After booking");
   ```

### 🚫 Debugging Don'ts

1. **Don't leave debugger statements in committed code**
2. **Don't use console.log for everything** - use the debug utilities
3. **Don't debug in production environment**
4. **Don't forget to clean up test data after debugging**

## Troubleshooting

### Common Issues

**Chrome DevTools not connecting:**

```bash
# Try different port
node --inspect-brk=9230 debug-single-test.js event-capacity
```

**VS Code breakpoints not working:**

- Ensure you're using the correct launch configuration
- Check that source maps are working
- Verify file paths in launch.json

**Tests timing out in debug mode:**

- Debug mode has longer timeouts
- Use `NODE_ENV=debug` for extended timeouts
- Break down complex tests into smaller parts

**Memory issues during debugging:**

```bash
# Increase memory limit
node --max-old-space-size=4096 --inspect-brk debug-single-test.js event-capacity
```

### Getting Help

1. **Check the debug output** - The debug utilities provide detailed information
2. **Use the interactive debugger** - Call `debug.interactiveDebugger()` for guided debugging
3. **Create data snapshots** - Compare before/after states
4. **Enable verbose logging** - Set `NODE_ENV=debug` for detailed output

## Advanced Debugging

### Custom Debug Configurations

Create your own debug script:

```javascript
// my-debug.js
import debug from "./shared/utilities/debug-utils.js";
import { EventsFixtures } from "./features/events/fixtures.js";

async function customDebugSession() {
  const fixtures = new EventsFixtures();

  // Your custom debugging logic
  debug.debugBreakpoint("Starting custom debug session");

  // Create test data
  const event = await fixtures.createTestEvent();
  await debug.inspectDatabaseState();

  // More debugging...
}

customDebugSession();
```

### Environment Variables

```bash
# Enable detailed logging
NODE_ENV=debug npm run debug:capacity

# Custom debug settings
DEBUG_CLEANUP=true npm run debug:cleanup
DEBUG_QUERIES=true npm run debug:booking
```

This debugging setup gives you comprehensive tools to debug your integration tests effectively!

