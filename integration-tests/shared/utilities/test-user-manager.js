import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";
import { supabase } from "../../config/database.js";

// Ensure env loaded when running via tests
dotenv.config();

/**
 * TestUserManager provides utilities to:
 * - Ensure a user exists (by role or explicit email)
 * - Assign roles
 * - Sign in with the anon client and obtain an authenticated Supabase client
 * - Call RPCs as a specific role/user
 */
export class TestUserManager {
  constructor(options = {}) {
    // Support multiple common env var names
    this.supabaseUrl = process.env.SUPABASE_URL;
    this.anonKey = process.env.ANON_KEY;

    this.defaultPassword = process.env.TEST_USER_PASSWORD;
    this.testUserId = process.env.TEST_USER_ID || null;

    if (!this.supabaseUrl || !this.anonKey) {
      throw new Error("Missing SUPABASE_URL or ANON_KEY for TestUserManager");
    }

    // Service-role client imported as `supabase` for admin operations
    // Anon client will be created per sign-in to attach session state
    this._anon = createClient(this.supabaseUrl, this.anonKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });
  }

  async signIn({ email, password }) {
    const { error } = await this._anon.auth.signInWithPassword({
      email,
      password,
    });
    if (error) throw new Error(`Sign-in failed for ${email}: ${error.message}`);
    return this._anon; // now authenticated
  }

  getUserId() {
    return this.testUserId; // must be provided via env
  }

  async ensureRole(userId, role) {
    if (!role || !userId) return;
    const { error: roleErr } = await supabase.rpc("exec_sql", {
      sql_query:
        "insert into public.user_roles (user_id, role) values ($1, $2::user_role) on conflict (user_id) do update set role = excluded.role, updated_at = now();",
      params: [userId, role],
    });
    if (roleErr) {
      await supabase
        .from("user_roles")
        .upsert({ user_id: userId, role }, { onConflict: "user_id" });
    }
  }

  async asUser(email, password) {
    const client = await this.signIn({
      email,
      password: password || this.defaultPassword,
    });
    const userId = this.getUserId();
    return { client, user: { id: userId, email } };
  }

  async asRole(role, options = {}) {
    // Use provided account but set role if requested
    const email = options.email;
    const password = options.password || this.defaultPassword;
    if (!email) throw new Error("asRole requires an existing email");
    const client = await this.signIn({ email, password });
    const userId = this.getUserId();
    await this.ensureRole(userId, role);
    return { client, user: { id: userId, email } };
  }

  async callAsRole(functionName, params, role, options = {}) {
    const { client } = await this.asRole(role, options);
    const { data, error } = await client.rpc(functionName, params);
    return { data, error };
  }
}

export default TestUserManager;
