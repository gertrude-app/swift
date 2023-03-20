import Dependencies

public struct FilterClient: Sendable {
  public var setup: @Sendable () async -> FilterState
  public var start: @Sendable () async -> FilterState
  public var stop: @Sendable () async -> FilterState
  public var state: @Sendable () async -> FilterState
  public var install: @Sendable () async -> FilterInstallResult

  public init(
    setup: @escaping @Sendable () async -> FilterState,
    start: @escaping @Sendable () async -> FilterState,
    stop: @escaping @Sendable () async -> FilterState,
    state: @escaping @Sendable () async -> FilterState,
    install: @escaping @Sendable () async -> FilterInstallResult
  ) {
    self.setup = setup
    self.start = start
    self.stop = stop
    self.state = state
    self.install = install
  }
}

extension FilterClient: TestDependencyKey {
  public static let testValue = Self(
    setup: { .on },
    start: { .on },
    stop: { .off },
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
