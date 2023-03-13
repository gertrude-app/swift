import Dependencies
import Foundation

struct ApiClient: Sendable {
  var connectUser: @Sendable (Int) async throws -> User
}

extension ApiClient: DependencyKey {
  static let liveValue = Self(
    connectUser: { code in
      try await Task.sleep(nanoseconds: 1_000_000_000)
      return User(
        token: UUID(),
        name: "Huck",
        keyloggingEnabled: true,
        screenshotsEnabled: true,
        screenshotFrequency: 1,
        screenshotSize: 1,
        connectedAt: Date()
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
