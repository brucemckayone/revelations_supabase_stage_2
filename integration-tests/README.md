# Integration Testing System - AI Navigation Guide

**This README serves as a simple index directing AI assistants to the right documentation.**

## 🎯 Quick Navigation for AI

| **What you need to do**     | **Look at this file**                                 |
| --------------------------- | ----------------------------------------------------- |
| Add a new feature test      | [`FEATURE_TEMPLATE.md`](./FEATURE_TEMPLATE.md)        |
| See a complete example      | [`EXAMPLE_NEW_FEATURE.md`](./EXAMPLE_NEW_FEATURE.md)  |
| Understand the architecture | [Project Structure](#project-structure) below         |
| Implement core framework    | [Implementation Status](#implementation-status) below |

## Project Structure

```
integration-tests/
├── config/           # Database, users, environment setup
├── core/             # Test framework, cleanup coordinator
├── features/         # Individual feature test modules
│   └── {feature}/    # Each feature: index.js, fixtures.js, cleanup.js, tests/
├── shared/           # Utilities, constants, types
└── runners/          # Test execution orchestration
```

## Implementation Status

| Component            | Status     | What to do                                         |
| -------------------- | ---------- | -------------------------------------------------- |
| **Templates & Docs** | ✅ Done    | Use [`FEATURE_TEMPLATE.md`](./FEATURE_TEMPLATE.md) |
| **Core Framework**   | ⚠️ Missing | Implement `core/` and `shared/utilities/`          |
| **Credit System**    | ✅ Exists  | Legacy format, needs refactoring                   |
| **Other Features**   | ⚠️ Missing | Use [`FEATURE_TEMPLATE.md`](./FEATURE_TEMPLATE.md) |

## Files You Need to Create

1. `shared/utilities/test-utils.js` - Assertions, database helpers
2. `config/test-users.js` - User management
3. `core/test-framework.js` - TestSuite, TestFixtures classes
4. `core/cleanup-coordinator.js` - Multi-feature cleanup

## Key Rules

- **Use `TEST_` prefix** for all test data (required for cleanup)
- **Each feature is isolated** - no shared cleanup files
- **Follow the template** in [`FEATURE_TEMPLATE.md`](./FEATURE_TEMPLATE.md) exactly
- **See working example** in [`EXAMPLE_NEW_FEATURE.md`](./EXAMPLE_NEW_FEATURE.md)

---

**For AI: Don't read this README for implementation details. Go to the template files.**
