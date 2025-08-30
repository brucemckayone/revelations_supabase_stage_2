// @ts-check
import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";

/**
 * @typedef {import("../../supabase/database.types.js").Database} Database
 * @typedef {import("@supabase/supabase-js").SupabaseClient<Database>} TypedSupabaseClient
 */

// Load environment variables
dotenv.config();

// Environment Configuration
// Create a .env file in the integration-tests directory with:
// SUPABASE_URL=your_supabase_url
// SUPABASE_ANON_KEY=your_supabase_anon_key
// SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

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
 * @type {TypedSupabaseClient}
 */
export const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

/**
 * Test database connection by querying events table
 * @returns {Promise<boolean>} True if connection successful, false otherwise
 */
export async function testConnection() {
  try {
    // Test connection by querying a table we know exists and can access
    // TypeScript will ensure 'events' table exists and 'id' column is valid
    const { data, error } = await supabase.from("events").select("id").limit(1);

    if (error) {
      throw error;
    }

    console.log("✅ Database connection successful");
    return true;
  } catch (error) {
    console.error("❌ Database connection failed:", error.message);
    return false;
  }
}

/**
 * Test configuration with type safety
 * @type {Readonly<{
 *   CREATOR_USER_ID: string;
 *   TEST_PREFIX: string;
 *   TIMEOUT_MS: number;
 *   DELAY_BETWEEN_TESTS: number;
 *   MAX_TEST_RECORDS: number;
 *   VERBOSE: boolean;
 * }>}
 */
export const TEST_CONFIG = {
  /** Known test user from seed data */
  CREATOR_USER_ID: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",

  /** Test data prefixes to identify and clean up test records */
  TEST_PREFIX: "TEST_",

  /** Timeouts and delays */
  TIMEOUT_MS: 30000,
  DELAY_BETWEEN_TESTS: 100,

  /** Test data limits */
  MAX_TEST_RECORDS: 100,

  /** Verbose logging */
  VERBOSE:
    process.env.VERBOSE_LOGGING === "true" ||
    process.argv.includes("--verbose"),
};

/**
 * @typedef {Database["public"]["Tables"]} DatabaseTables
 * @typedef {DatabaseTables["events"]} EventsTable
 * @typedef {DatabaseTables["posts"]} PostsTable
 * @typedef {DatabaseTables["tickets"]} TicketsTable
 * @typedef {DatabaseTables["event_bookings"]} EventBookingsTable
 * @typedef {DatabaseTables["purchases"]} PurchasesTable
 * @typedef {DatabaseTables["universal_packages"]} UniversalPackagesTable
 */

/**
 * @typedef {EventsTable["Row"]} EventRow
 * @typedef {PostsTable["Row"]} PostRow
 * @typedef {TicketsTable["Row"]} TicketRow
 * @typedef {EventBookingsTable["Row"]} EventBookingRow
 * @typedef {PurchasesTable["Row"]} PurchaseRow
 * @typedef {UniversalPackagesTable["Row"]} UniversalPackageRow
 */

/**
 * @typedef {EventsTable["Insert"]} EventInsert
 * @typedef {PostsTable["Insert"]} PostInsert
 * @typedef {TicketsTable["Insert"]} TicketInsert
 * @typedef {EventBookingsTable["Insert"]} EventBookingInsert
 * @typedef {PurchasesTable["Insert"]} PurchaseInsert
 * @typedef {UniversalPackagesTable["Insert"]} UniversalPackageInsert
 */

/**
 * @typedef {EventsTable["Update"]} EventUpdate
 * @typedef {PostsTable["Update"]} PostUpdate
 * @typedef {TicketsTable["Update"]} TicketUpdate
 * @typedef {EventBookingsTable["Update"]} EventBookingUpdate
 * @typedef {PurchasesTable["Update"]} PurchaseUpdate
 * @typedef {UniversalPackagesTable["Update"]} UniversalPackageUpdate
 */

/**
 * Default export for backwards compatibility
 */
export default supabase;
