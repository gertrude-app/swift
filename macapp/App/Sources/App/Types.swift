import ClientInterfaces
import ComposableArchitecture
import Foundation
import Gertie
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

public extension ApiClient {
  func appCheckIn(_ filterVersion: String?) async throws -> CheckIn.Output {
    @Dependency(\.app) var appClient
    @Dependency(\.device) var device
    return try await self.checkIn(
      .init(
        appVersion: appClient.installedVersion() ?? "unknown",
        filterVersion: filterVersion,
        userIsAdmin: device.currentMacOsUserType() == .admin,
        osVersion: device.osVersion().semver
      )
    )
  }

  func securityEvent(_ event: SecurityEvent.MacApp, _ detail: String? = nil) async {
    @Dependency(\.storage) var storage
    guard let deviceId = try? await storage.loadPersistentState()?.user?.deviceId else {
      return
    }
    await self.securityEvent(deviceId: deviceId, event: event, detail: detail)
  }

  func securityEvent(deviceId: UUID, event: SecurityEvent.MacApp, detail: String? = nil) async {
    @Dependency(\.network) var network
    guard network.isConnected() else {
      // TODO: buffer/resend https://github.com/gertrude-app/project/issues/243
      return
    }
    await self.logSecurityEvent(.init(deviceId: deviceId, event: event.rawValue, detail: detail))
  }
}

extension URL {
  static let contact = URL(string: "https://gertrude.app/contact")!
}
