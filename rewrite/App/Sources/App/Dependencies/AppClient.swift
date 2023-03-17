import Dependencies
import Foundation

struct AppClient: Sendable {
  var installedVersion: @Sendable () -> String?
}

extension AppClient: DependencyKey {
  static let liveValue = Self(
    installedVersion: {
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
  )
}

extension AppClient: TestDependencyKey {
  static let testValue = Self(
    installedVersion: { "1.0.0" }
  )
}

extension DependencyValues {
  var app: AppClient {
    get { self[AppClient.self] }
    set { self[AppClient.self] = newValue }
  }
}
