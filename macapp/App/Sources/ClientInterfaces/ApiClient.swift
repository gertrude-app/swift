import Dependencies
import Foundation
import Gertie
import MacAppRoute

public struct ApiClient: Sendable {
  public var clearUserToken: @Sendable () async -> Void
  public var connectUser: @Sendable (ConnectUser.Input) async throws -> UserData
  public var createKeystrokeLines: @Sendable (CreateKeystrokeLines.Input) async throws -> Void
  public var createSuspendFilterRequest: @Sendable (CreateSuspendFilterRequest.Input) async throws
    -> Void
  public var createUnlockRequests: @Sendable (CreateUnlockRequests_v2.Input) async throws -> Void
  public var getAdminAccountStatus: @Sendable () async throws -> AdminAccountStatus
  public var latestAppVersion: @Sendable (LatestAppVersion.Input) async throws -> LatestAppVersion
    .Output
  public var logUnexpectedError: @Sendable (LogUnexpectedError.Input) async -> Void
  public var recentAppVersions: @Sendable () async throws -> [String: String]
  public var refreshRules: @Sendable (RefreshRules.Input) async throws -> RefreshRules.Output
  public var setAccountActive: @Sendable (Bool) async -> Void
  public var setUserToken: @Sendable (UUID) async -> Void
  public var uploadScreenshot: @Sendable (Data, Int, Int) async throws -> URL
  public var userData: @Sendable () async throws -> UserData

  public init(
    clearUserToken: @escaping @Sendable () async -> Void,
    connectUser: @escaping @Sendable (ConnectUser.Input) async throws -> UserData,
    createKeystrokeLines: @escaping @Sendable (CreateKeystrokeLines.Input) async throws -> Void,
    createSuspendFilterRequest: @escaping @Sendable (CreateSuspendFilterRequest.Input) async throws
      -> Void,
    createUnlockRequests: @escaping @Sendable (CreateUnlockRequests_v2.Input) async throws -> Void,
    getAdminAccountStatus: @escaping @Sendable () async throws -> AdminAccountStatus,
    latestAppVersion: @escaping @Sendable (LatestAppVersion.Input) async throws -> LatestAppVersion
      .Output,
    logUnexpectedError: @escaping @Sendable (LogUnexpectedError.Input) async -> Void,
    recentAppVersions: @escaping @Sendable () async throws -> [String: String],
    refreshRules: @escaping @Sendable (RefreshRules.Input) async throws -> RefreshRules.Output,
    setAccountActive: @escaping @Sendable (Bool) async -> Void,
    setUserToken: @escaping @Sendable (UUID) async -> Void,
    uploadScreenshot: @escaping @Sendable (Data, Int, Int) async throws -> URL,
    userData: @escaping @Sendable () async throws -> UserData
  ) {
    self.clearUserToken = clearUserToken
    self.connectUser = connectUser
    self.createKeystrokeLines = createKeystrokeLines
    self.createSuspendFilterRequest = createSuspendFilterRequest
    self.createUnlockRequests = createUnlockRequests
    self.getAdminAccountStatus = getAdminAccountStatus
    self.latestAppVersion = latestAppVersion
    self.logUnexpectedError = logUnexpectedError
    self.recentAppVersions = recentAppVersions
    self.refreshRules = refreshRules
    self.setAccountActive = setAccountActive
    self.setUserToken = setUserToken
    self.uploadScreenshot = uploadScreenshot
    self.userData = userData
  }
}

extension ApiClient: EndpointOverridable {
  #if DEBUG
    public static let endpointDefault = URL(string: "http://127.0.0.1:8080/pairql")!
  #else
    public static let endpointDefault = URL(string: "https://api.gertrude.app/pairql")!
  #endif

  public static let endpointOverride = LockIsolated<URL?>(nil)
}

public extension ApiClient {
  enum Error: Swift.Error {
    case accountInactive
    case missingUserToken
    case missingDataOrResponse
    case unexpectedError(statusCode: Int)
  }
}

extension ApiClient: TestDependencyKey {
  public static let testValue = Self(
    clearUserToken: {},
    connectUser: { _ in .mock },
    createKeystrokeLines: { _ in },
    createSuspendFilterRequest: { _ in },
    createUnlockRequests: { _ in },
    getAdminAccountStatus: { .active },
    latestAppVersion: { _ in .init(semver: "1.0.0") },
    logUnexpectedError: { _ in },
    recentAppVersions: { [:] },
    refreshRules: { _ in throw Error.missingUserToken },
    setAccountActive: { _ in },
    setUserToken: { _ in },
    uploadScreenshot: { _, _, _ in .init(string: "https://s3.buck.et/img.png")! },
    userData: { .mock }
  )
}

#if DEBUG
  public extension ApiClient {
    static let failing = Self(
      clearUserToken: unimplemented("ApiClient.clearUserToken"),
      connectUser: unimplemented("ApiClient.connectUser"),
      createKeystrokeLines: unimplemented("ApiClient.createKeystrokeLines"),
      createSuspendFilterRequest: unimplemented("ApiClient.createSuspendFilterRequest"),
      createUnlockRequests: unimplemented("ApiClient.createUnlockRequests"),
      getAdminAccountStatus: unimplemented("ApiClient.getAdminAccountStatus"),
      latestAppVersion: unimplemented("ApiClient.latestAppVersion"),
      logUnexpectedError: unimplemented("ApiClient.logUnexpectedError"),
      recentAppVersions: unimplemented("ApiClient.recentAppVersions"),
      refreshRules: unimplemented("ApiClient.refreshRules"),
      setAccountActive: unimplemented("ApiClient.setAccountActive"),
      setUserToken: unimplemented("ApiClient.setUserToken"),
      uploadScreenshot: unimplemented("ApiClient.uploadScreenshot"),
      userData: unimplemented("ApiClient.userData")
    )
  }
#endif

public extension DependencyValues {
  var api: ApiClient {
    get { self[ApiClient.self] }
    set { self[ApiClient.self] = newValue }
  }
}
