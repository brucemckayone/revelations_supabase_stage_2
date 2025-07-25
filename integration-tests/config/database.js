import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";

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

// Create Supabase client with service role for testing
export const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

// Database connection test
export async function testConnection() {
  try {
    // Test connection by querying a table we know exists and can access
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

// Test configuration
export const TEST_CONFIG = {
  // Known test user from seed data
  CREATOR_USER_ID: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",

  // Test data prefixes to identify and clean up test records
  TEST_PREFIX: "TEST_",

  // Timeouts and delays
  TIMEOUT_MS: 30000,
  DELAY_BETWEEN_TESTS: 100,

  // Test data limits
  MAX_TEST_RECORDS: 100,

  // Verbose logging
  VERBOSE:
    process.env.VERBOSE_LOGGING === "true" ||
    process.argv.includes("--verbose"),
};

export default supabase;
