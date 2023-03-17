import Dependencies
import Foundation
import MacAppRoute

public struct ApiClient: Sendable {
  public var connectUser: @Sendable (ConnectUser.Input) async throws -> User
  public var setEndpoint: @Sendable (URL) async -> Void
  public var setUserToken: @Sendable (User.Token) async -> Void

  public init(
    connectUser: @escaping @Sendable (ConnectUser.Input) async throws -> User,
    setEndpoint: @escaping @Sendable (URL) async -> Void,
    setUserToken: @escaping @Sendable (User.Token) async -> Void
  ) {
    self.connectUser = connectUser
    self.setEndpoint = setEndpoint
    self.setUserToken = setUserToken
  }
}

extension ApiClient: TestDependencyKey {
  public static let testValue = Self(
    connectUser: { code in
      User(
        id: .init(),
        token: .init(),
        deviceId: .init(),
        name: "Huck",
        keyloggingEnabled: true,
        screenshotsEnabled: true,
        screenshotFrequency: 1,
        screenshotSize: 1
      )
    },
    setEndpoint: { _ in },
    setUserToken: { _ in }
  )
}

public extension DependencyValues {
  var api: ApiClient {
    get { self[ApiClient.self] }
    set { self[ApiClient.self] = newValue }
  }
}
