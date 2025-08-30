// Test Users Configuration
// Uses existing real users from the database for testing

import { supabase } from "./database.js";
import { log, queryDatabase } from "../utils/test-helpers.js";

/**
 * Test users cache to avoid repeated queries
 */
const testUsersCache = new Map();

/**
 * Available test user roles
 */
export const TEST_ROLES = {
  ADMIN: "admin",
  CREATOR: "creator",
  MODERATOR: "moderator",
  USER: "user",
};

/**
 * Known real user IDs from the database (we'll fetch these dynamically)
 */
const KNOWN_USERS = {
  ADMIN: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11", // brucemckayone@gmail.com
  USER: "17b34512-b19b-4791-b2cc-ae65871c88e9", // a@g.com
  CREATOR: "759517af-cb7a-4710-b95b-7cfca6f08694", // user2@example.com (we'll make this creator)
};

/**
 * Get test users for integration tests
 * Returns users that can be used in tests
 */
export async function getTestUsers(count = 1) {
  // Use known real user IDs from the database
  const realUsers = [
    {
      id: "41b3bd84-530a-4d03-80be-34dcc91154f3",
      email: "bruce.r.mckay@gmail.com",
    },
    { id: "17b34512-b19b-4791-b2cc-ae65871c88e9", email: "a@g.com" },
    { id: "759517af-cb7a-4710-b95b-7cfca6f08694", email: "user2@example.com" },
  ];

  return realUsers.slice(0, count);
}

/**
 * Set up authentication context for testing
 * This simulates a user being logged in for database functions that use auth.uid()
 */
export async function setupTestAuth(userId) {
  // For testing, we can use the test user ID
  // In a real app, this would involve setting JWT tokens
  return userId;
}

/**
 * Get a test user with a specific role
 * @param {string} role - User role (admin, creator, moderator, user)
 * @returns {Promise<Object>} User object with specified role
 */
export async function getTestUserByRole(role) {
  // Check cache first
  const cacheKey = `role_${role}`;
  if (testUsersCache.has(cacheKey)) {
    return testUsersCache.get(cacheKey);
  }

  try {
    log(`Fetching user with role: ${role}`, "debug");

    // Special handling for creator role - use specific user and ensure role
    if (role === "creator") {
      // First ensure the user has creator role
      await queryDatabase(
        `
        UPDATE public.user_roles 
        SET role = 'creator'::user_role, updated_at = now()
        WHERE user_id = $1
      `,
        [KNOWN_USERS.CREATOR]
      );
    }

    const result = await queryDatabase(
      `
      SELECT 
        u.id,
        u.email,
        ur.role
      FROM auth.users u
      JOIN public.user_roles ur ON u.id = ur.user_id
      WHERE ur.role = $1::user_role
      LIMIT 1
    `,
      [role]
    );

    if (result.error) {
      throw new Error(
        `Failed to fetch user with role ${role}: ${result.error.message}`
      );
    }

    if (!result.data || result.data.length === 0) {
      // Fallback: Use known users and assign role if needed
      const fallbackUserId =
        KNOWN_USERS[role.toUpperCase()] || KNOWN_USERS.USER;

      // Try to create the role if it doesn't exist
      await queryDatabase(
        `
        UPDATE public.user_roles 
        SET role = $1::user_role, updated_at = now()
        WHERE user_id = $2
      `,
        [role, fallbackUserId]
      );

      // Fetch the user after role assignment
      const fallbackResult = await queryDatabase(
        `
        SELECT 
          u.id,
          u.email,
          ur.role
        FROM auth.users u
        JOIN public.user_roles ur ON u.id = ur.user_id
        WHERE u.id = $1
      `,
        [fallbackUserId]
      );

      if (fallbackResult.data && fallbackResult.data.length > 0) {
        const user = fallbackResult.data[0];
        testUsersCache.set(cacheKey, user);
        log(`Using fallback user for role ${role}: ${user.email}`, "debug");
        return user;
      }

      throw new Error(`No user found with role: ${role}`);
    }

    const user = result.data[0];
    testUsersCache.set(cacheKey, user);

    log(`Found user with role ${role}: ${user.email}`, "debug");
    return user;
  } catch (error) {
    log(`Failed to get user with role ${role}: ${error.message}`, "error");
    throw error;
  }
}

/**
 * Get a single test user (defaults to regular user role)
 * @returns {Promise<Object>} User object
 */
export async function getSingleTestUser() {
  return await getTestUserByRole(TEST_ROLES.USER);
}

/**
 * Get the admin test user
 * @returns {Promise<Object>} Admin user object
 */
export async function getAdminUser() {
  return await getTestUserByRole(TEST_ROLES.ADMIN);
}

/**
 * Get the creator test user
 * @returns {Promise<Object>} Creator user object
 */
export async function getCreatorUser() {
  return await getTestUserByRole(TEST_ROLES.CREATOR);
}

/**
 * Get the moderator test user
 * @returns {Promise<Object>} Moderator user object
 */
export async function getModeratorUser() {
  return await getTestUserByRole(TEST_ROLES.MODERATOR);
}

/**
 * Get multiple users for multi-user testing scenarios
 * @param {Object} options - Configuration for user types needed
 * @returns {Promise<Object>} Object with different user types
 */
export async function getTestUserSet(options = {}) {
  const {
    includeAdmin = true,
    includeCreator = true,
    includeModerator = false,
    includeUsers = 2,
  } = options;

  const userSet = {};

  try {
    if (includeAdmin) {
      userSet.admin = await getAdminUser();
    }

    if (includeCreator) {
      userSet.creator = await getCreatorUser();
    }

    if (includeModerator) {
      userSet.moderator = await getModeratorUser();
    }

    if (includeUsers > 0) {
      // Get multiple regular users
      const users = await queryDatabase(
        `
        SELECT 
          u.id,
          u.email,
          ur.role
        FROM auth.users u
        JOIN public.user_roles ur ON u.id = ur.user_id
        WHERE ur.role = 'user'::user_role
        ORDER BY u.email
        LIMIT $1
      `,
        [includeUsers]
      );

      if (users.data && users.data.length > 0) {
        userSet.users = users.data;
        userSet.user1 = users.data[0];
        if (users.data.length > 1) {
          userSet.user2 = users.data[1];
        }
      }
    }

    log(
      `Created test user set with ${Object.keys(userSet).length} user types`,
      "debug"
    );
    return userSet;
  } catch (error) {
    log(`Failed to create test user set: ${error.message}`, "error");
    throw error;
  }
}

/**
 * Clear the test users cache
 */
export function clearTestUsersCache() {
  testUsersCache.clear();
  log("Test users cache cleared", "debug");
}

/**
 * Validate that a user ID exists in the database
 * @param {string} userId - User ID to validate
 * @returns {Promise<boolean>} True if user exists
 */
export async function validateTestUser(userId) {
  try {
    const result = await queryDatabase(
      `
      SELECT 1 FROM auth.users WHERE id = $1
    `,
      [userId]
    );

    return result.data && result.data.length > 0;
  } catch (error) {
    log(`Failed to validate user ${userId}: ${error.message}`, "error");
    return false;
  }
}

/**
 * Get test user statistics
 * @returns {Promise<Object>} Statistics about users
 */
export async function getTestUserStats() {
  try {
    const result = await queryDatabase(`
      SELECT 
        ur.role,
        count(*) as count
      FROM auth.users u
      JOIN public.user_roles ur ON u.id = ur.user_id
      GROUP BY ur.role
      ORDER BY ur.role
    `);

    if (result.error) {
      throw new Error(`Failed to get user stats: ${result.error.message}`);
    }

    const stats = {
      total: 0,
      by_role: {},
    };

    if (result.data) {
      result.data.forEach((row) => {
        stats.by_role[row.role] = parseInt(row.count);
        stats.total += parseInt(row.count);
      });
    }

    return stats;
  } catch (error) {
    log(`Failed to get user stats: ${error.message}`, "error");
    throw error;
  }
}
