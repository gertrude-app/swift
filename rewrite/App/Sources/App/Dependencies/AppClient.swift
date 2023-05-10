import Dependencies
import Foundation
import MacAppRoute
import Models

struct AppClient: Sendable {
  var installedVersion: @Sendable () -> String?
  var quit: @Sendable () async -> Void
}

extension AppClient: DependencyKey {
  static let liveValue = Self(
    installedVersion: {
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    },
    quit: {
      exit(0)
    }
  )
}

extension AppClient: TestDependencyKey {
  static let testValue = Self(
    installedVersion: { "1.0.0" },
    quit: {}
  )
}

extension DependencyValues {
  var app: AppClient {
    get { self[AppClient.self] }
    set { self[AppClient.self] = newValue }
  }
}

extension ApiClient {
  func refreshUserRules() async throws -> RefreshRules.Output {
    @Dependency(\.app) var appClient
    return try await refreshRules(
      .init(appVersion: appClient.installedVersion() ?? "unknown")
    )
  }
}
