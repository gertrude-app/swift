# PairQL System Architecture

## Overview

PairQL is a type-safe RPC (Remote Procedure Call) system built on top of Swift's
URLRouting library. It enables strongly-typed client-server communication across multiple
client types (macOS app, iOS app, dashboard, podcast app) with a single unified API
server.

## Core Components

### 1. PairQL Core Package (`pairql/`)

The foundation library defining the PairQL protocol:

**Key Protocols:**

- `Pair` - Defines an operation with typed Input/Output and authentication level
- `PairInput` - Codable input data sent to server
- `PairOutput` - Codable output data returned from server
- `PairRoute` - Groups related Pairs into route hierarchies

**Built-in Types:**

- `NoInput` - For operations without input
- `SuccessOutput` - Simple boolean success response
- `ClientAuth` - Auth levels: none, child, parent, superAdmin
- `PqlError` - Standardized error structure with user/debug messages

**Key Feature:** Uses Swift's type system + URLRouting to generate bidirectional
parsers/printers for URLs and JSON bodies.

### 2. Domain-Specific Route Packages

Each client type has its own package defining available operations:

#### `pairql-macapp/` - macOS Application Routes

- **UnauthedRoute:** `ConnectUser`, `TrustedTime`, `RecentAppVersions`,
  `LogInterestingEvent`
- **AuthedUserRoute:** `CheckIn`, `CreateUnlockRequests`, `LogFilterEvents`,
  `LogSecurityEvent`, `ReportBrowsers`, `CreateScreenshotUpload`, etc.
- Auth via `X-UserToken` header (UUID)

#### `pairql-iosapp/` - iOS Application Routes

- **UnauthedRoute:** `ConnectDevice`, `BlockRules`, `DefaultBlockRules`, `LogIOSEvent`,
  `RecoveryDirective`
- **AuthedRoute:** `ConnectedRules`, `CreateSuspendFilterRequest`,
  `PollFilterSuspensionDecision`, `ScreenshotUploadUrl`
- Auth via `X-DeviceToken` header (UUID)

#### `pairql-podcasts/` - Podcast Application Routes

- Currently only unauthed routes
- Domain: `gertrude-am`

#### Dashboard & SuperAdmin Routes (defined in `api/`)

- **Dashboard:** Parent/admin operations with `X-AdminToken` authentication
- **SuperAdmin:** System administration with `X-SuperAdminToken` authentication

### 3. API Server (`api/`)

#### Router Setup (`api/Sources/Api/Configure/router.swift`)

Main entry point:

```
POST /pairql/:domain/:operation
```

Routes to `PairQLRoute.handler()` which dispatches to domain-specific handlers.

#### Request Flow (`api/Sources/Api/Routes/PairQL.swift:68-114`)

1. **Parse URL path:** Extract domain from `/pairql/:domain/:operation`
2. **Route matching:** URLRouting parses request into typed `PairQLRoute` enum:

   - `.macApp(MacAppRoute)` - domain: `macos-app`
   - `.iOS(IOSRoute)` - domain: `ios-app`
   - `.dashboard(DashboardRoute)` - domain: `dashboard`
   - `.podcast(PodcastRoute)` - domain: `gertrude-am`
   - `.superAdmin(SuperAdminRoute)` - domain: `super-admin`

3. **Context creation:** Builds `Context` with requestId, dashboardUrl, ipAddress

4. **Route dispatch:** Calls `PairQLRoute.respond(to:in:)` which delegates to
   domain-specific responder

5. **Authentication:** Each domain responder extracts auth headers and validates tokens:

   - MacApp: Looks up `X-UserToken` → finds `MacAppToken` → loads child/user
   - iOS: Looks up `X-DeviceToken` → finds `IOSApp.Token` → loads device/child
   - Dashboard: Looks up `X-AdminToken` → finds `Parent.DashToken` → loads parent

6. **Resolver execution:** Calls domain-specific `Resolver.resolve(with:in:)` with
   validated context

7. **Response generation:**
   - Success: Converts `PairOutput` to JSON response (200 OK)
   - Error: Converts `PqlError` to JSON response with appropriate status code

#### Resolver Pattern (`api/Sources/Api/PairQL/ResolverTypes.swift`)

Server-side implementation protocol:

```swift
protocol Resolver: Pair {
  associatedtype Context: ResolverContext
  static func resolve(with input: Input, in context: Context) async throws -> Output
}
```

Each `Pair` operation has a corresponding `Resolver` implementation in the API that
performs the business logic.

#### Error Handling

- Parsing errors → `PqlError` with `.notFound` type (route not found)
- `PqlError` thrown → Returned as JSON with matching HTTP status
- `PqlErrorConvertible` (DuetSQL, Stripe errors) → Converted to `PqlError`
- Unknown errors → Rethrown as 500

## Domain Routing

The API serves 5 distinct domains on a single endpoint:

| Domain        | Path Prefix            | Auth Header         | Client Type     |
| ------------- | ---------------------- | ------------------- | --------------- |
| `macos-app`   | `/pairql/macos-app/`   | `X-UserToken`       | Mac application |
| `ios-app`     | `/pairql/ios-app/`     | `X-DeviceToken`     | iOS application |
| `dashboard`   | `/pairql/dashboard/`   | `X-AdminToken`      | Web dashboard   |
| `gertrude-am` | `/pairql/gertrude-am/` | None                | Podcast app     |
| `super-admin` | `/pairql/super-admin/` | `X-SuperAdminToken` | Admin tools     |

## How to Add a New PairQL Pair

Follow these steps to add a new operation to the PairQL system (using `PodcastProducts` as
an example):

### 1. Define the Pair in Domain Package

Create a new file in the appropriate domain package (e.g.,
`pairql-podcasts/Sources/PodcastRoute/UnauthedPairs/`):

```swift
// pairql-podcasts/Sources/PodcastRoute/UnauthedPairs/PodcastProducts.swift
import Foundation
import PairQL

public struct PodcastProducts: Pair {
  public static let auth: ClientAuth = .none

  public typealias Input = NoInput      // Or define custom Input struct
  public typealias Output = [String]    // Define your output type
}
```

**Key points:**

- Struct name becomes the operation name in URLs
- Set `auth` level (`.none`, `.child`, `.parent`, `.superAdmin`)
- Use `NoInput` for operations without input, or define custom `Input: PairInput`
- Output must conform to `PairOutput` (most Codable types already do)

### 2. Add to Route Enum

Update the route enum in the domain package:

```swift
// pairql-podcasts/Sources/PodcastRoute/UnauthedRoute.swift
public enum UnauthedRoute: PairRoute {
  case logPodcastEvent(LogPodcastEvent.Input)
  case podcastProducts  // Add new case (no associated value if NoInput)
}
```

### 3. Wire Up Router

Add routing configuration to the parser:

```swift
// pairql-podcasts/Sources/PodcastRoute/UnauthedRoute.swift
public extension UnauthedRoute {
  static let router: AnyParserPrinter<URLRequestData, UnauthedRoute> = OneOf {
    Route(.case(Self.logPodcastEvent)) {
      Operation(LogPodcastEvent.self)
      Body(.json(LogPodcastEvent.Input.self))
    }
    Route(.case(Self.podcastProducts)) {
      Operation(PodcastProducts.self)
      // No Body() needed for NoInput
    }
  }
  .eraseToAnyParserPrinter()
}
```

### 4. Add Resolver in API

Create the server-side implementation in the API:

```swift
// api/Sources/Api/PairQL/Podcast/PodcastRoute.swift

// Add case to RouteResponder
extension PodcastRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .unauthed(let unauthed):
      switch unauthed {
      case .podcastProducts:
        let output = try await PodcastProducts.resolve(in: context)
        return try await self.respond(with: output)
      // ... other cases
      }
    }
  }
}

// Implement resolver logic
extension PodcastProducts: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    // implement here
  }
}
```

**Notes:**

- Use `Resolver` protocol for pairs with input: `resolve(with: Input, in: Context)`
- Use `NoInputResolver` for pairs without input: `resolve(in: Context)`
- Access database via `context.db`
- Throw `PqlError` for business logic errors

### 5. Add Tests

Create test file in `api/Tests/ApiTests/`:

```swift
// api/Tests/ApiTests/PodcastPairResolvers/PodcastProductsResolverTests.swift
import Foundation
import PodcastRoute
import XCTest
import XExpect

@testable import Api

final class PodcastProductsResolverTests: ApiTestCase, @unchecked Sendable {
  func testPodcastProductsReturnsProductList() async throws {
    let output = try await PodcastProducts.resolve(in: .mock)

    expect(output).toHaveCount(3)
    expect(output[0]).toEqual("Gertrude App for macOS")
  }
}
```

### 6. Build and Test

```bash
# Build the domain package
cd pairql-podcasts && swift build

# Build and test the API
swift test --package-path ./api --filter PodcastProductsResolverTests
```

### Summary Checklist

- [ ] Create Pair struct in domain package with Input/Output types
- [ ] Add enum case to appropriate Route enum
- [ ] Add Route to router's OneOf parser
- [ ] Add case to RouteResponder.respond() switch
- [ ] Implement Resolver extension with business logic
- [ ] Create test file and verify resolver works
- [ ] Build both packages to ensure no compile errors

The operation is now accessible at `POST /pairql/{domain}/{PairName}`
