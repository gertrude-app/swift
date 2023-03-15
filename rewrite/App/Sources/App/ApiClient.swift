import Dependencies
import Foundation
import Models

struct ApiClient: Sendable {
  var connectUser: @Sendable (Int) async throws -> User
}

extension ApiClient: TestDependencyKey {
  static let testValue = Self(
    connectUser: { code in
      try await Task.sleep(nanoseconds: 1_000_000_000)
      return User(
        name: "Huck",
        keyloggingEnabled: true,
        screenshotsEnabled: true,
        screenshotFrequency: 1,
        screenshotSize: 1
      )
    }
  )
}

extension DependencyValues {
  var apiClient: ApiClient {
    get { self[ApiClient.self] }
    set { self[ApiClient.self] = newValue }
  }
}
