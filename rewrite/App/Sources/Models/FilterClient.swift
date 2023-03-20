import Dependencies

public struct FilterClient: Sendable {
  public var setup: @Sendable () async -> FilterState
  public var start: @Sendable () async throws -> Void
  public var state: @Sendable () async throws -> FilterState
  public var install: @Sendable () async throws -> FilterInstallResult

  public init(
    setup: @escaping @Sendable () async -> FilterState,
    start: @escaping @Sendable () async throws -> Void,
    state: @escaping @Sendable () async throws -> FilterState,
    install: @escaping @Sendable () async throws -> FilterInstallResult
  ) {
    self.setup = setup
    self.start = start
    self.state = state
    self.install = install
  }
}

extension FilterClient: TestDependencyKey {
  public static let testValue = Self(
    setup: { .on },
    start: {},
    state: { .on },
    install: { .installedSuccessfully }
  )
}

public extension DependencyValues {
  var filter: FilterClient {
    get { self[FilterClient.self] }
    set { self[FilterClient.self] = newValue }
  }
}
