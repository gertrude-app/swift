import Dependencies
import Foundation
import MacAppRoute

public struct ApiClient: Sendable {
  public var connectUser: @Sendable (ConnectUser.Input) async throws -> User
  public var createUnlockRequests: @Sendable (CreateUnlockRequests_v2.Input) async throws
    -> CreateUnlockRequests_v2.Output
  public var refreshRules: @Sendable (RefreshRules.Input) async throws -> RefreshRules.Output
  public var setEndpoint: @Sendable (URL) async -> Void
  public var setUserToken: @Sendable (User.Token) async -> Void

  public init(
    connectUser: @escaping @Sendable (ConnectUser.Input) async throws -> User,
    createUnlockRequests: @escaping @Sendable (CreateUnlockRequests_v2.Input) async throws
      -> CreateUnlockRequests_v2.Output,
    refreshRules: @escaping @Sendable (RefreshRules.Input) async throws -> RefreshRules.Output,
    setEndpoint: @escaping @Sendable (URL) async -> Void,
    setUserToken: @escaping @Sendable (User.Token) async -> Void
  ) {
    self.connectUser = connectUser
    self.createUnlockRequests = createUnlockRequests
    self.refreshRules = refreshRules
    self.setEndpoint = setEndpoint
    self.setUserToken = setUserToken
  }
}

#if DEBUG
  extension ApiClient: TestDependencyKey {
    public static let testValue = Self(
      connectUser: { _ in .mock },
      createUnlockRequests: { _ in .success },
      refreshRules: { _ in .mock },
      setEndpoint: { _ in },
      setUserToken: { _ in }
    )
  }
#endif

public extension DependencyValues {
  var api: ApiClient {
    get { self[ApiClient.self] }
    set { self[ApiClient.self] = newValue }
  }
}
