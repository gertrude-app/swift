import ClientInterfaces
import ComposableArchitecture
import Foundation
import MacAppRoute
import os.log

typealias FeatureReducer = Reducer

protocol Feature {
  associatedtype State: Equatable
  associatedtype Action: Equatable, Sendable
  associatedtype Reducer: FeatureReducer
}

struct AbsurdReducer<State: Equatable, Sendable>: FeatureReducer {
  func reduce(into state: inout State, action: Never) -> Effect<Never> {}
}

extension Feature where Action == Never {
  typealias Reducer = AbsurdReducer<State, Action>
}

protocol RootReducing: Reducer {
  associatedtype State = AppReducer.State
  associatedtype Action = AppReducer.Action
}

protocol AdminAuthenticating: RootReducing {
  var security: SecurityClient { get }
}

extension AdminAuthenticating where Action == AppReducer.Action {
  func adminAuthenticated(_ action: Action) -> Effect<Action> {
    .run { [didAuthenticateAsAdmin = security.didAuthenticateAsAdmin] send in
      if await didAuthenticateAsAdmin() {
        await send(.adminAuthed(action))
      }
    }
  }
}

enum HeartbeatInterval: Equatable, Sendable {
  case everyMinute
  case everyFiveMinutes
  case everyTwentyMinutes
  case everyHour
  case everySixHours
}

enum NotificationsSetting: String, Equatable, Codable {
  case none
  case banner
  case alert
}

struct PendingRequest: Equatable, Codable {
  var id: UUID
  var createdAt: Date
}

public extension ApiClient {
  func appCheckIn(
    _ filterVersion: String?,
    pendingFilterSuspension: UUID? = nil,
    pendingUnlockRequests: [UUID]? = nil,
    sendNamedApps: Bool = false
  ) async throws -> CheckIn_v2.Output {
    @Dependency(\.app) var appClient
    @Dependency(\.device) var device
    return try await self.checkIn(
      .init(
        appVersion: appClient.installedVersion() ?? "unknown",
        filterVersion: filterVersion,
        userIsAdmin: device.currentMacOsUserType() == .admin,
        osVersion: device.osVersion().semver.string,
        pendingFilterSuspension: pendingFilterSuspension,
        pendingUnlockRequests: pendingUnlockRequests,
        namedApps: sendNamedApps ? device.listRunningApps().filter(\.hasName) : nil
      )
    )
  }
}

extension URL {
  static let contact = URL(string: "https://gertrude.app/contact")!
}

struct AppError: Error, Equatable, Sendable {
  var message: String

  init(_ message: String) {
    self.message = message
  }

  init(oslogging message: String, context: String? = nil) {
    if let context {
      os_log("[G•] AppError context: %{public}s, message: %{public}s", context, message)
    } else {
      os_log("[G•] AppError message: %{public}s", message)
    }
    self.message = message
  }
}

extension AppError: ExpressibleByStringLiteral {
  init(stringLiteral value: String) {
    self.message = value
  }
}
