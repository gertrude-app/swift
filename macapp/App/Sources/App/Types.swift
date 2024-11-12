import ClientInterfaces
import ComposableArchitecture
import Foundation
import MacAppRoute

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
    pendingUnlockRequests: [UUID]? = nil
  ) async throws -> CheckIn_v2.Output {
    @Dependency(\.app) var appClient
    @Dependency(\.device) var device
    return try await self.checkIn(
      .init(
        appVersion: appClient.installedVersion() ?? "unknown",
        filterVersion: filterVersion,
        userIsAdmin: device.currentMacOsUserType() == .admin,
        osVersion: device.osVersion().semver,
        pendingFilterSuspension: pendingFilterSuspension,
        pendingUnlockRequests: pendingUnlockRequests
      )
    )
  }
}

extension URL {
  static let contact = URL(string: "https://gertrude.app/contact")!
}
