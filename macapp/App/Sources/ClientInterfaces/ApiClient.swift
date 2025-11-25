import Dependencies
import Foundation
import Gertie
import MacAppRoute

public struct ApiClient: Sendable {
  public var checkIn: @Sendable (CheckIn_v2.Input) async throws -> CheckIn_v2.Output
  public var clearUserToken: @Sendable () async -> Void
  public var connectUser: @Sendable (ConnectUser.Input) async throws -> UserData
  public var createKeystrokeLines: @Sendable (CreateKeystrokeLines.Input) async throws -> Void
  public var createSuspendFilterRequest: @Sendable (CreateSuspendFilterRequest_v2.Input)
    async throws -> UUID
  public var createUnlockRequests: @Sendable (CreateUnlockRequests_v3.Input) async throws -> [UUID]
  public var getUserToken: @Sendable () async throws -> UUID?
  public var logFilterEvents: @Sendable (LogFilterEvents.Input) async -> Void
  public var logInterestingEvent: @Sendable (LogInterestingEvent.Input) async -> Void
  public var logSecurityEvent: @Sendable (LogSecurityEvent.Input, UUID?) async -> Void
  public var recentAppVersions: @Sendable () async throws -> [String: String]
  public var reportBrowsers: @Sendable (ReportBrowsers.Input) async throws -> Void
  public var setAccountActive: @Sendable (Bool) async -> Void
  public var setUserToken: @Sendable (UUID) async -> Void
  public var trustedNetworkTimestamp: @Sendable () async throws -> Double
  public var uploadScreenshot: @Sendable (UploadScreenshotData) async throws -> URL

  public init(
    checkIn: @escaping @Sendable (CheckIn_v2.Input) async throws -> CheckIn_v2.Output,
    clearUserToken: @escaping @Sendable () async -> Void,
    connectUser: @escaping @Sendable (ConnectUser.Input) async throws -> UserData,
    createKeystrokeLines: @escaping @Sendable (CreateKeystrokeLines.Input) async throws -> Void,
    createSuspendFilterRequest: @escaping @Sendable (
      CreateSuspendFilterRequest_v2.Input,
    ) async throws -> UUID,
    createUnlockRequests: @escaping @Sendable (CreateUnlockRequests_v3.Input) async throws
      -> [UUID],
    getUserToken: @escaping @Sendable () async throws -> UUID?,
    logFilterEvents: @escaping @Sendable (LogFilterEvents.Input) async -> Void,
    logInterestingEvent: @escaping @Sendable (LogInterestingEvent.Input) async -> Void,
    logSecurityEvent: @escaping @Sendable (LogSecurityEvent.Input, UUID?) async -> Void,
    recentAppVersions: @escaping @Sendable () async throws -> [String: String],
    reportBrowsers: @escaping @Sendable (ReportBrowsers.Input) async throws -> Void,
    setAccountActive: @escaping @Sendable (Bool) async -> Void,
    setUserToken: @escaping @Sendable (UUID) async -> Void,
    trustedNetworkTimestamp: @escaping @Sendable () async throws -> Double,
    uploadScreenshot: @escaping @Sendable (UploadScreenshotData) async throws -> URL,
  ) {
    self.checkIn = checkIn
    self.clearUserToken = clearUserToken
    self.connectUser = connectUser
    self.createKeystrokeLines = createKeystrokeLines
    self.createSuspendFilterRequest = createSuspendFilterRequest
    self.createUnlockRequests = createUnlockRequests
    self.getUserToken = getUserToken
    self.logFilterEvents = logFilterEvents
    self.logInterestingEvent = logInterestingEvent
    self.logSecurityEvent = logSecurityEvent
    self.recentAppVersions = recentAppVersions
    self.reportBrowsers = reportBrowsers
    self.setAccountActive = setAccountActive
    self.setUserToken = setUserToken
    self.trustedNetworkTimestamp = trustedNetworkTimestamp
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
  struct UploadScreenshotData: Sendable, Equatable {
    public var image: Data
    public var width: Int
    public var height: Int
    public var filterSuspended: Bool
    public var createdAt: Date

    public init(image: Data, width: Int, height: Int, filterSuspended: Bool, createdAt: Date) {
      self.image = image
      self.width = width
      self.height = height
      self.filterSuspended = filterSuspended
      self.createdAt = createdAt
    }
  }
}

public extension ApiClient {
  enum Error: Swift.Error, Equatable {
    case accountInactive
    case missingUserToken
    case missingDataOrResponse
    case unexpectedError(statusCode: Int)
  }
}

extension ApiClient: TestDependencyKey {
  public static let testValue = Self(
    checkIn: unimplemented("ApiClient.checkIn"),
    clearUserToken: unimplemented("ApiClient.clearUserToken"),
    connectUser: unimplemented("ApiClient.connectUser"),
    createKeystrokeLines: unimplemented("ApiClient.createKeystrokeLines"),
    createSuspendFilterRequest: unimplemented("ApiClient.createSuspendFilterRequest"),
    createUnlockRequests: unimplemented("ApiClient.createUnlockRequests"),
    getUserToken: unimplemented("ApiClient.getUserToken"),
    logFilterEvents: unimplemented("ApiClient.logFilterEvents"),
    logInterestingEvent: unimplemented("ApiClient.logInterestingEvent"),
    logSecurityEvent: unimplemented("ApiClient.logSecurityEvent"),
    recentAppVersions: unimplemented("ApiClient.recentAppVersions"),
    reportBrowsers: unimplemented("ApiClient.reportBrowsers"),
    setAccountActive: unimplemented("ApiClient.setAccountActive"),
    setUserToken: unimplemented("ApiClient.setUserToken"),
    trustedNetworkTimestamp: unimplemented("ApiClient.trustedNetworkTimestamp"),
    uploadScreenshot: unimplemented("ApiClient.uploadScreenshot"),
  )

  public static let mock = Self(
    checkIn: { _ in throw Error.unexpectedError(statusCode: 999) },
    clearUserToken: {},
    connectUser: { _ in throw Error.unexpectedError(statusCode: 888) },
    createKeystrokeLines: { _ in },
    createSuspendFilterRequest: { _ in .init() },
    createUnlockRequests: { _ in [] },
    getUserToken: { nil },
    logFilterEvents: { _ in },
    logInterestingEvent: { _ in },
    logSecurityEvent: { _, _ in },
    recentAppVersions: { [:] },
    reportBrowsers: { _ in },
    setAccountActive: { _ in },
    setUserToken: { _ in },
    trustedNetworkTimestamp: { 0.0 },
    uploadScreenshot: { _ in .init(string: "https://s3.buck.et/img.png")! },
  )
}

public extension DependencyValues {
  var api: ApiClient {
    get { self[ApiClient.self] }
    set { self[ApiClient.self] = newValue }
  }
}
