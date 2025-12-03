# Gertrude Parental Controls - Swift Monorepo

## Overview

- **Product:** Gertrude - Parental controls and monitoring system for macOS and iOS
- **Repository:** Swift-based monorepo containing macOS app, iOS app, API server, and
  shared libraries

## Important notes

When writing code, almost NEVER leave comments, unless something is extremely non-obvious.

When running any `swift test` commands, always prepend `SWIFT_DETERMINISTIC_HASHING=1`

Never run `xcodebuild` for any reason.

Never make git commits unless I specifically ask you to.

If you need a UUID, use bash to invoke `uuid --llm` to get one, instead of making one
yourself. Many places in this codebase we use partial identifiers (especially for
logging), like `c05ef986`, if you need one of those, invode `sid --llm`.

## Quick Reference

- **Swift Version:** 6.2.1
- **Build System:** Swift Package Manager + Nx + Just
- **State Management:** The Composable Architecture (TCA)
- **API Pattern:** PairQL (type-safe RPC over HTTP)
- **Backend:** Vapor 4 + PostgreSQL 17 + Custom Duet ORM

## Repository Structure

```
swift/
├── api/               # Vapor 4 API server (PostgreSQL db)
├── macapp/            # macOS app
├── iosapp/            # iOS app
├── gertie/            # Core domain models (shared across platforms)
├── duet/              # Custom lightweight ORM
├── pairql/            # Type-safe RPC core library
├── pairql-macapp/     # macOS API pairql route definitions
├── pairql-iosapp/     # iOS API pairql route definitions
├── pairql-podcasts/   # Podcast app (not in monorepo) pairql API routes
├── ts-interop/        # TypeScript code generation
└── docs/              # Documentation
```

## The Three Main Applications

### 1. macOS App (`macapp/`)

**Structure:**

- `Xcode/Gertrude.xcodeproj` - Xcode project
- `App/` - SPM package with all business logic

**Key Features:**

- System-level network filtering (Network Extension)
- Keystroke logging
- Screenshot monitoring
- App blocking
- Filter suspension with parent approval
- Health check and self-healing system
- WebSocket real-time updates
- XPC communication (app ↔ filter extension)

**Tech Stack:**

- TCA (v1.2.0+) for state management
- Web views for UI, no SwiftUI
- Network Extension Framework for filtering
- XPC for inter-process communication
- Starscream for WebSockets
- Sparkle for auto-updates

**Key Modules:**

- `App` - Main app feature (TCA-based)
- `Filter` - Network filter extension
- `Core` - Shared types
- `ClientInterfaces` - Dependency protocols
- `Live*Client` - Live implementations (API, WebSocket, XPC, etc.)

### 2. iOS App (`iosapp/`)

**Description**:

An iOS app designed to plug the holes in Screen Time, including blocking #images GIF
searches, and more

**Structure:**

- `Gertrude-iOS.xcodeproj` - Xcode project
- `lib-ios/` - SPM package with core logic
- `app/` - Main app target
- `controller/` - Controller extension target
- `filter/` - Network filter extension target

**Key Features:**

- Content filtering via Network Extension
- Device management controller
- Parent-controlled filtering rules
- Filter suspension requests
- Recovery mode and failsafes

**Tech Stack:**

- TCA (v1.18.0+) for state management
- SwiftUI for UI
- Network Extension Framework
- PairQL for API communication
- Point-Free Dependencies for DI

**Key Modules (lib-ios):**

- `LibCore` - Core iOS types
- `LibFilter` - Network filtering logic
- `LibController` - Device management
- `LibClients` - API clients
- `LibApp` - Main app UI (TCA-based)

### 3. API Server (`api/`)

**Deployment:** api.gertrude.app

**Tech Stack:**

- Vapor 4 (v4.104.0)
- PostgreSQL 17
- Duet + DuetSQL (custom ORM abstraction over Fluent)
- PairQL for type-safe routing

**API PairQL Domains:**

- `macos-app` - Mac app routes
- `ios-app` - iOS app routes
- `dashboard` - Web dashboard routes
- `gertrude-am` - Podcast app routes
- `super-admin` - Admin tools

**External Integrations:**

- Stripe (payments)
- Postmark (email)
- Slack (notifications)
- AWS S3 (storage)

**Deployment:**

- GitHub Actions CI/CD builds binary with ssh/scp deployment
- Separate production/staging builds
- see `./docs/api-build.md` for details on ci build

## Core Shared Libraries

### `gertie/` - Domain Models

- **Purpose:** Core domain types shared across macOS, iOS, and API
- **Products:** `Gertie`, `GertieIOS`

### `duet/` - Custom ORM

**Purpose:** Type-safe database abstraction over Fluent/PostgreSQL

### `pairql/` - Type-Safe RPC Core

**Purpose:** Foundation for all client-server communication

**Key Concepts:**

- `Pair<Input, Output>` - Request/response pair
- `PairInput` - Request data
- `PairOutput` - Response data
- `ClientAuth` - Authentication types
- `PqlError` - Standardized error handling
- Uses URLRouting for bidirectional parser/printer
- Custom fork of swift-url-routing (avoids swift-syntax dependency)

**Architecture:** See `./docs/pairql.md` for comprehensive documentation

### `pairql-macapp/` & `pairql-iosapp/`

**Purpose:** Platform-specific API route definitions **Shared Between:** API server and
client apps

### Utility Libraries (`x-*` packages)

All `x-*` libraries:

- Follow Point-Free dependency injection patterns
- Zero or minimal dependencies
- MIT licensed
- Platform support: macOS (.v12+) or cross-platform (.v10_15+)

**`x-kit/`** - Core utilities (XCore, XBase64) **`x-http/`** - Zero-dependency HTTP client
(async/await, JSON/form support) **`x-expect/`** - Testing assertions with better diffs
**`x-aws/`** - AWS S3 client with swift-crypto signing **`x-slack/`** - Slack messaging
(text + blocks) **`x-stripe/`** - Stripe payment client (USD only, intentional)
**`x-postmark/`** - Postmark email delivery

## Key Architectural Patterns

### The Composable Architecture (TCA)

**Used By:** macOS app, iOS app

**Benefits:**

- Unidirectional data flow
- Effect system for side effects
- Testable by default (reducer composition)
- Dependencies library for DI

## Development Workflow

### Build Commands (Just)

```bash
just test     # Run all tests
just build    # Build all packages
just lint-fix # Fix formatting
# more in justfile
```

### Testing

**Framework:** XCTest + x-expect **Coverage:** 239 test files across monorepo **CI:**
GitHub Actions (Linux + macOS + iOS)

**Test Commands:**

```bash
just test                                                     # All tests
cd api && SWIFT_DETERMINISTIC_HASHING=1 swift test            # API tests only
cd macapp/App && SWIFT_DETERMINISTIC_HASHING=1 swift test     # macOS app tests
cd iosapp/lib-ios && SWIFT_DETERMINISTIC_HASHING=1 swift test # iOS app tests
```

### Package Manager

- **SPM** - Primary package manager (17 packages)
- **pnpm** (v10.12.1) - For npm dependencies (Nx, TypeScript)
- **Nx** - Monorepo task caching

## Notable Files

### Documentation

- `/docs/pairql.md` - PairQL architecture (comprehensive, 281 lines)
- `macapp/readme.md` - macOS release notes and procedures
- `iosapp/readme.md` - iOS release notes and config
- `api/readme.md` - Docker setup instructions
- Individual library READMEs for public packages

## Common Tasks & Locations

### Adding a New API Endpoint

- see `./docs/pairql.md`

### Adding a Database Migration

- read several examples in `api/Sources/Api/Database/Migrations/` to see pattern

### Other database tasks

- see `./claude/skills/database/SKILL.md`
