import { log } from "../shared/utilities/test-utils.js";

/**
 * Cleanup Coordinator - orchestrates cleanup across multiple features
 * Respects feature dependencies and cleanup order
 */
export class CleanupCoordinator {
  constructor() {
    this.features = new Map(); // feature name -> { cleanupFn, order, dependencies }
    this.isRunning = false;
  }

  /**
   * Register a feature for cleanup coordination
   * @param {string} name - Feature name
   * @param {Function} cleanupFn - Cleanup function that returns promise
   * @param {number} order - Cleanup order (higher numbers cleaned first)
   * @param {Array<string>} dependencies - Features that depend on this one
   */
  registerFeature(name, cleanupFn, order = 1, dependencies = []) {
    this.features.set(name, {
      name,
      cleanupFn,
      order,
      dependencies,
    });

    log(`Registered feature for cleanup: ${name} (order: ${order})`, "debug");
  }

  /**
   * Unregister a feature
   * @param {string} name - Feature name
   */
  unregisterFeature(name) {
    this.features.delete(name);
    log(`Unregistered feature: ${name}`, "debug");
  }

  /**
   * Get cleanup order respecting dependencies
   * @returns {Array<Object>} Sorted features by cleanup order
   */
  getCleanupOrder() {
    const features = Array.from(this.features.values());

    // Sort by order (higher numbers first), then by dependencies
    return features.sort((a, b) => {
      // First sort by cleanup order (descending)
      if (a.order !== b.order) {
        return b.order - a.order;
      }

      // If same order, sort by dependencies (independent features first)
      if (a.dependencies.length !== b.dependencies.length) {
        return a.dependencies.length - b.dependencies.length;
      }

      // Finally, sort alphabetically for consistency
      return a.name.localeCompare(b.name);
    });
  }

  /**
   * Run cleanup for all registered features
   * @param {Array<string>} onlyFeatures - Optional: only clean specific features
   * @returns {Promise<Object>} Cleanup results
   */
  async cleanupAll(onlyFeatures = null) {
    if (this.isRunning) {
      throw new Error("Cleanup is already running");
    }

    this.isRunning = true;

    try {
      log("🧹 Starting coordinated cleanup...", "info");

      const results = {
        totalFeatures: 0,
        successfulFeatures: 0,
        failedFeatures: 0,
        totalRecordsCleaned: 0,
        featureResults: {},
        errors: [],
        startTime: Date.now(),
      };

      // Get features to clean (filtered if specified)
      let featuresToClean = this.getCleanupOrder();
      if (onlyFeatures) {
        featuresToClean = featuresToClean.filter((f) =>
          onlyFeatures.includes(f.name)
        );
      }

      results.totalFeatures = featuresToClean.length;

      if (featuresToClean.length === 0) {
        log("No features registered for cleanup", "warning");
        return results;
      }

      log(`Cleaning up ${featuresToClean.length} features in order:`, "info");
      featuresToClean.forEach((f) => {
        log(`  - ${f.name} (order: ${f.order})`, "info");
      });

      // Run cleanup for each feature in order
      for (const feature of featuresToClean) {
        try {
          log(`🧹 Cleaning feature: ${feature.name}`, "info");

          const featureStartTime = Date.now();
          const recordsCleaned = await feature.cleanupFn();
          const featureDuration = Date.now() - featureStartTime;

          results.successfulFeatures++;
          results.totalRecordsCleaned += recordsCleaned || 0;
          results.featureResults[feature.name] = {
            success: true,
            recordsCleaned: recordsCleaned || 0,
            duration: featureDuration,
          };

          log(
            `✅ Completed ${feature.name}: ${
              recordsCleaned || 0
            } records cleaned`,
            "success"
          );
        } catch (error) {
          results.failedFeatures++;
          results.errors.push({
            feature: feature.name,
            error: error.message,
            stack: error.stack,
          });
          results.featureResults[feature.name] = {
            success: false,
            error: error.message,
            duration: 0,
          };

          log(`❌ Failed to clean ${feature.name}: ${error.message}`, "error");
        }
      }

      results.endTime = Date.now();
      results.duration = results.endTime - results.startTime;

      // Log final results
      log("🧹 Coordinated cleanup completed:", "info");
      log(
        `  ✅ Successful: ${results.successfulFeatures}/${results.totalFeatures} features`,
        "info"
      );
      log(`  📊 Records cleaned: ${results.totalRecordsCleaned}`, "info");
      log(`  ⏱️  Duration: ${(results.duration / 1000).toFixed(2)}s`, "info");

      if (results.failedFeatures > 0) {
        log(`  ❌ Failed: ${results.failedFeatures} features`, "error");
      }

      return results;
    } finally {
      this.isRunning = false;
    }
  }

  /**
   * Run cleanup for a specific feature
   * @param {string} featureName - Feature name
   * @returns {Promise<Object>} Cleanup result
   */
  async cleanupFeature(featureName) {
    if (!this.features.has(featureName)) {
      throw new Error(`Feature not registered: ${featureName}`);
    }

    const feature = this.features.get(featureName);

    try {
      log(`🧹 Cleaning specific feature: ${featureName}`, "info");

      const startTime = Date.now();
      const recordsCleaned = await feature.cleanupFn();
      const duration = Date.now() - startTime;

      log(
        `✅ Completed ${featureName}: ${recordsCleaned || 0} records cleaned`,
        "success"
      );

      return {
        feature: featureName,
        success: true,
        recordsCleaned: recordsCleaned || 0,
        duration,
      };
    } catch (error) {
      log(`❌ Failed to clean ${featureName}: ${error.message}`, "error");

      return {
        feature: featureName,
        success: false,
        error: error.message,
        duration: 0,
      };
    }
  }

  /**
   * Verify all features have been cleaned
   * @returns {Promise<Object>} Verification results
   */
  async verifyCleanup() {
    log("🔍 Verifying cleanup completion...", "info");

    const verificationResults = {
      totalFeatures: this.features.size,
      verifiedFeatures: 0,
      failedVerifications: 0,
      featureResults: {},
    };

    for (const [featureName, feature] of this.features) {
      try {
        // If feature has a verify function, use it
        if (feature.verifyFn && typeof feature.verifyFn === "function") {
          const verified = await feature.verifyFn();

          if (verified) {
            verificationResults.verifiedFeatures++;
            verificationResults.featureResults[featureName] = {
              verified: true,
            };
          } else {
            verificationResults.failedVerifications++;
            verificationResults.featureResults[featureName] = {
              verified: false,
              error: "Verification failed",
            };
          }
        } else {
          // Skip verification if no verify function
          verificationResults.featureResults[featureName] = {
            verified: null,
            note: "No verification function provided",
          };
        }
      } catch (error) {
        verificationResults.failedVerifications++;
        verificationResults.featureResults[featureName] = {
          verified: false,
          error: error.message,
        };
        log(
          `Verification failed for ${featureName}: ${error.message}`,
          "warning"
        );
      }
    }

    if (verificationResults.failedVerifications === 0) {
      log("✅ All cleanup verifications passed", "success");
    } else {
      log(
        `⚠️  ${verificationResults.failedVerifications} cleanup verifications failed`,
        "warning"
      );
    }

    return verificationResults;
  }

  /**
   * Get status of registered features
   * @returns {Object} Status information
   */
  getStatus() {
    const features = Array.from(this.features.values());
    const cleanupOrder = this.getCleanupOrder();

    return {
      isRunning: this.isRunning,
      totalFeatures: features.length,
      features: features.map((f) => ({
        name: f.name,
        order: f.order,
        dependencies: f.dependencies,
      })),
      cleanupOrder: cleanupOrder.map((f) => f.name),
    };
  }
}

// Global singleton instance
export const cleanupCoordinator = new CleanupCoordinator();
