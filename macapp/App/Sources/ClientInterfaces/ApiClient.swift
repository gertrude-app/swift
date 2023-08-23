import Dependencies
import Foundation
import Gertie
import MacAppRoute

public struct ApiClient: Sendable {
  public var checkIn: @Sendable (CheckIn.Input) async throws -> CheckIn.Output
  public var clearUserToken: @Sendable () async -> Void
  public var connectUser: @Sendable (ConnectUser.Input) async throws -> UserData
  public var createKeystrokeLines: @Sendable (CreateKeystrokeLines.Input) async throws -> Void
  public var createSuspendFilterRequest: @Sendable (CreateSuspendFilterRequest.Input) async throws
    -> Void
  public var createUnlockRequests: @Sendable (CreateUnlockRequests_v2.Input) async throws -> Void
  public var logInterestingEvent: @Sendable (LogInterestingEvent.Input) async -> Void
  public var recentAppVersions: @Sendable () async throws -> [String: String]
  public var setAccountActive: @Sendable (Bool) async -> Void
  public var setUserToken: @Sendable (UUID) async -> Void
  public var uploadScreenshot: @Sendable (Data, Int, Int, Date) async throws -> URL

  public init(
    checkIn: @escaping @Sendable (CheckIn.Input) async throws -> CheckIn.Output,
    clearUserToken: @escaping @Sendable () async -> Void,
    connectUser: @escaping @Sendable (ConnectUser.Input) async throws -> UserData,
    createKeystrokeLines: @escaping @Sendable (CreateKeystrokeLines.Input) async throws -> Void,
    createSuspendFilterRequest: @escaping @Sendable (CreateSuspendFilterRequest.Input) async throws
      -> Void,
    createUnlockRequests: @escaping @Sendable (CreateUnlockRequests_v2.Input) async throws -> Void,
    logInterestingEvent: @escaping @Sendable (LogInterestingEvent.Input) async -> Void,
    recentAppVersions: @escaping @Sendable () async throws -> [String: String],
    setAccountActive: @escaping @Sendable (Bool) async -> Void,
    setUserToken: @escaping @Sendable (UUID) async -> Void,
    uploadScreenshot: @escaping @Sendable (Data, Int, Int, Date) async throws -> URL
  ) {
    self.checkIn = checkIn
    self.clearUserToken = clearUserToken
    self.connectUser = connectUser
    self.createKeystrokeLines = createKeystrokeLines
    self.createSuspendFilterRequest = createSuspendFilterRequest
    self.createUnlockRequests = createUnlockRequests
    self.logInterestingEvent = logInterestingEvent
    self.recentAppVersions = recentAppVersions
    self.setAccountActive = setAccountActive
    self.setUserToken = setUserToken
    self.uploadScreenshot = uploadScreenshot
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
    checkIn: { _ in .mock },
    clearUserToken: {},
    connectUser: { _ in .mock },
    createKeystrokeLines: { _ in },
    createSuspendFilterRequest: { _ in },
    createUnlockRequests: { _ in },
    logInterestingEvent: { _ in },
    recentAppVersions: { [:] },
    setAccountActive: { _ in },
    setUserToken: { _ in },
    uploadScreenshot: { _, _, _, _ in .init(string: "https://s3.buck.et/img.png")! }
  )
}

#if DEBUG
  public extension ApiClient {
    static let failing = Self(
      checkIn: unimplemented("ApiClient.checkIn"),
      clearUserToken: unimplemented("ApiClient.clearUserToken"),
      connectUser: unimplemented("ApiClient.connectUser"),
      createKeystrokeLines: unimplemented("ApiClient.createKeystrokeLines"),
      createSuspendFilterRequest: unimplemented("ApiClient.createSuspendFilterRequest"),
      createUnlockRequests: unimplemented("ApiClient.createUnlockRequests"),
      logInterestingEvent: unimplemented("ApiClient.logInterestingEvent"),
      recentAppVersions: unimplemented("ApiClient.recentAppVersions"),
      setAccountActive: unimplemented("ApiClient.setAccountActive"),
      setUserToken: unimplemented("ApiClient.setUserToken"),
      uploadScreenshot: unimplemented("ApiClient.uploadScreenshot")
    )
  }
#endif

public extension DependencyValues {
  var api: ApiClient {
    get { self[ApiClient.self] }
    set { self[ApiClient.self] = newValue }
  }
}
