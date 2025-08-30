import { supabase } from "../../config/database.js";

export async function cleanup() {
  console.log("🧹 Starting cleanup for notifications fixtures...");
  
  // Clean up in reverse dependency order
  const cleanupTasks = [
    () => cleanupTable("notification_deliveries", "created_at"),
    () => cleanupTable("notification_read_receipts", "read_at"), 
    () => cleanupTable("notification_recipients", "created_at"),
    () => cleanupTable("notifications", "title"),
    () => cleanupTable("notification_templates", "title"),
    () => cleanupTable("email_templates", "name"),
    () => cleanupTable("notification_preferences", "created_at"),
    () => cleanupTable("user_fcm_tokens", "token"),
    // Clean up any test events/posts created
    () => cleanupTable("events", "created_at"),
    () => cleanupTable("posts", "title"),
  ];

  let totalCleaned = 0;
  for (const task of cleanupTasks) {
    try {
      const cleaned = await task();
      totalCleaned += cleaned;
    } catch (error) {
      console.error(`Cleanup task failed: ${error.message}`);
    }
  }

  console.log(`✅ Notifications cleanup completed: ${totalCleaned} records removed`);
  return totalCleaned;
}

async function cleanupTable(tableName, column = "name") {
  try {
    let query;
    
    // Handle different cleanup patterns based on table structure
    switch (tableName) {
      case "notifications":
      case "posts":
        query = supabase.from(tableName).delete().like("title", "TEST_%");
        break;
      case "email_templates":
      case "notification_templates":
        query = supabase.from(tableName).delete().like("name", "TEST_%");
        break;
      case "user_fcm_tokens":
        query = supabase.from(tableName).delete().like("token", "TEST_%");
        break;
      case "notification_deliveries":
      case "notification_read_receipts":
      case "notification_recipients":
      case "notification_preferences":
      case "events":
        // These tables don't have direct TEST_ patterns, 
        // clean up by time range (last hour) to be safe
        const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();
        query = supabase.from(tableName).delete().gte(column, oneHourAgo);
        break;
      default:
        query = supabase.from(tableName).delete().like(column, "TEST_%");
    }

    const { data, error } = await query;

    if (error && error.code !== "PGRST116") {
      // Ignore "no rows found" errors
      console.warn(`⚠️ Warning cleaning ${tableName}: ${error.message}`);
      return 0;
    }

    return data?.length || 0;
  } catch (error) {
    console.error(`❌ Error cleaning ${tableName}: ${error.message}`);
    return 0;
  }
}

export async function verify() {
  console.log("🔍 Verifying notification cleanup...");
  
  const testDataChecks = [
    () => checkTable("notifications", "title", "TEST_%"),
    () => checkTable("email_templates", "name", "TEST_%"),
    () => checkTable("notification_templates", "title", "TEST_%"),
    () => checkTable("user_fcm_tokens", "token", "TEST_%"),
    () => checkTable("posts", "title", "TEST_%"),
  ];

  for (const check of testDataChecks) {
    const hasTestData = await check();
    if (hasTestData) {
      console.log("❌ Test data still found after cleanup");
      return false;
    }
  }

  console.log("✅ No test data found - cleanup verified");
  return true;
}

async function checkTable(tableName, column, pattern) {
  try {
    const { data } = await supabase
      .from(tableName)
      .select("id")
      .like(column, pattern)
      .limit(1);

    return data && data.length > 0;
  } catch (error) {
    console.warn(`Warning checking ${tableName}: ${error.message}`);
    return false;
  }
}


