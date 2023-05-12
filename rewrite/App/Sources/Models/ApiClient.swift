import Dependencies
import Foundation
import MacAppRoute
import Shared

public struct ApiClient: Sendable {
  public var clearUserToken: @Sendable () async -> Void
  public var connectUser: @Sendable (ConnectUser.Input) async throws -> User
  public var createUnlockRequests: @Sendable (CreateUnlockRequests_v2.Input) async throws
    -> CreateUnlockRequests_v2.Output
  public var getAdminAccountStatus: @Sendable () async throws -> AdminAccountStatus
  public var latestAppVersion: @Sendable (ReleaseChannel) async throws -> String
  public var refreshRules: @Sendable (RefreshRules.Input) async throws -> RefreshRules.Output
  public var setEndpoint: @Sendable (URL) async -> Void
  public var setUserToken: @Sendable (User.Token) async -> Void
  public var uploadScreenshot: @Sendable (Data, Int, Int) async throws -> URL

  public init(
    clearUserToken: @escaping @Sendable () async -> Void,
    connectUser: @escaping @Sendable (ConnectUser.Input) async throws -> User,
    createUnlockRequests: @escaping @Sendable (CreateUnlockRequests_v2.Input) async throws
      -> CreateUnlockRequests_v2.Output,
    getAdminAccountStatus: @escaping @Sendable () async throws -> AdminAccountStatus,
    latestAppVersion: @escaping @Sendable (ReleaseChannel) async throws -> String,
    refreshRules: @escaping @Sendable (RefreshRules.Input) async throws -> RefreshRules.Output,
    setEndpoint: @escaping @Sendable (URL) async -> Void,
    setUserToken: @escaping @Sendable (User.Token) async -> Void,
    uploadScreenshot: @escaping @Sendable (Data, Int, Int) async throws -> URL
  ) {
    self.clearUserToken = clearUserToken
    self.connectUser = connectUser
    self.createUnlockRequests = createUnlockRequests
    self.getAdminAccountStatus = getAdminAccountStatus
    self.latestAppVersion = latestAppVersion
    self.refreshRules = refreshRules
    self.setEndpoint = setEndpoint
    self.setUserToken = setUserToken
    self.uploadScreenshot = uploadScreenshot
  }
}

#if DEBUG
  extension ApiClient: TestDependencyKey {
    public static let testValue = Self(
      clearUserToken: {},
      connectUser: { _ in .mock },
      createUnlockRequests: { _ in .success },
      getAdminAccountStatus: { .active },
      latestAppVersion: { _ in "1.0.0" },
      refreshRules: { _ in .mock },
      setEndpoint: { _ in },
      setUserToken: { _ in },
      uploadScreenshot: { _, _, _ in .init(string: "https://s3.buck.et/img.png")! }
    )
  }
#endif

public extension DependencyValues {
  var api: ApiClient {
    get { self[ApiClient.self] }
    set { self[ApiClient.self] = newValue }
  }
}
