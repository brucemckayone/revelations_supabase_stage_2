import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import dotenv from "dotenv";
import type { Database } from "../../supabase/database.types.js";

// Load environment variables
dotenv.config();

// Environment Configuration
// Create a .env file in the integration-tests directory with:
// SUPABASE_URL=your_supabase_url
// SUPABASE_ANON_KEY=your_supabase_anon_key
// SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

const supabaseUrl: string | undefined = process.env.SUPABASE_URL;
const supabaseServiceKey: string | undefined =
  process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error("❌ Missing required environment variables:");
  console.error("   SUPABASE_URL:", supabaseUrl ? "✅" : "❌ Missing");
  console.error(
    "   SUPABASE_SERVICE_ROLE_KEY:",
    supabaseServiceKey ? "✅" : "❌ Missing"
  );
  console.error(
    "\nCreate a .env file in the integration-tests directory with your Supabase credentials."
  );
  process.exit(1);
}

/**
 * Type-safe Supabase client with full Database schema
 * Provides autocomplete and type checking for all tables, views, and functions
 */
export const supabase: SupabaseClient<Database> = createClient<Database>(
  supabaseUrl!,
  supabaseServiceKey!,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

/**
 * Test database connection by querying events table
 * @returns Promise<boolean> - True if connection successful, false otherwise
 */
export async function testConnection(): Promise<boolean> {
  try {
    // Test connection by querying a table we know exists and can access
    // TypeScript will ensure 'events' table exists and 'id' column is valid
    const { data, error } = await supabase.from("events").select("id").limit(1);

    if (error) {
      throw error;
    }

    console.log("✅ Database connection successful");
    return true;
  } catch (error: any) {
    console.error("❌ Database connection failed:", error.message);
    return false;
  }
}

/**
 * Test configuration with type safety
 */
export const TEST_CONFIG = {
  /** Known test user from seed data */
  CREATOR_USER_ID: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11" as const,

  /** Test data prefixes to identify and clean up test records */
  TEST_PREFIX: "TEST_" as const,

  /** Timeouts and delays */
  TIMEOUT_MS: 30000 as const,
  DELAY_BETWEEN_TESTS: 100 as const,

  /** Test data limits */
  MAX_TEST_RECORDS: 100 as const,

  /** Verbose logging */
  VERBOSE: (process.env.VERBOSE_LOGGING === "true" ||
    process.argv.includes("--verbose")) as boolean,
} as const;

// Export commonly used database types for type safety in tests
export type DatabaseTables = Database["public"]["Tables"];
export type EventsTable = DatabaseTables["events"];
export type PostsTable = DatabaseTables["posts"];
export type TicketsTable = DatabaseTables["tickets"];
export type EventBookingsTable = DatabaseTables["event_bookings"];
export type PurchasesTable = DatabaseTables["purchases"];
export type UniversalPackagesTable = DatabaseTables["universal_packages"];

// Row types for easier use in tests
export type EventRow = EventsTable["Row"];
export type PostRow = PostsTable["Row"];
export type TicketRow = TicketsTable["Row"];
export type EventBookingRow = EventBookingsTable["Row"];
export type PurchaseRow = PurchasesTable["Row"];
export type UniversalPackageRow = UniversalPackagesTable["Row"];

// Insert types for creating records
export type EventInsert = EventsTable["Insert"];
export type PostInsert = PostsTable["Insert"];
export type TicketInsert = TicketsTable["Insert"];
export type EventBookingInsert = EventBookingsTable["Insert"];
export type PurchaseInsert = PurchasesTable["Insert"];
export type UniversalPackageInsert = UniversalPackagesTable["Insert"];

// Update types for modifying records
export type EventUpdate = EventsTable["Update"];
export type PostUpdate = PostsTable["Update"];
export type TicketUpdate = TicketsTable["Update"];
export type EventBookingUpdate = EventBookingsTable["Update"];
export type PurchaseUpdate = PurchasesTable["Update"];
export type UniversalPackageUpdate = UniversalPackagesTable["Update"];

/**
 * Default export for backwards compatibility
 */
export default supabase;
