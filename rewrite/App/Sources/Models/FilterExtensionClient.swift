import Combine
import Dependencies

public struct FilterExtensionClient: Sendable {
  public var setup: @Sendable () async -> FilterState
  public var start: @Sendable () async -> FilterState
  public var stop: @Sendable () async -> FilterState
  public var state: @Sendable () async -> FilterState
  public var install: @Sendable () async -> FilterInstallResult
  public var stateChanges: @Sendable () -> AnyPublisher<FilterState, Never>

  public init(
    setup: @escaping @Sendable () async -> FilterState,
    start: @escaping @Sendable () async -> FilterState,
    stop: @escaping @Sendable () async -> FilterState,
    state: @escaping @Sendable () async -> FilterState,
    install: @escaping @Sendable () async -> FilterInstallResult,
    stateChanges: @escaping @Sendable () -> AnyPublisher<FilterState, Never>
  ) {
    self.setup = setup
    self.start = start
    self.stop = stop
    self.state = state
    self.install = install
    self.stateChanges = stateChanges
  }
}

extension FilterExtensionClient: TestDependencyKey {
  public static let testValue = Self(
    setup: { .on },
    start: { .on },
    stop: { .off },
    state: { .on },
    install: { .installedSuccessfully },
    stateChanges: { Empty().eraseToAnyPublisher() }
  )
}

public extension DependencyValues {
  var filterExtension: FilterExtensionClient {
    get { self[FilterExtensionClient.self] }
    set { self[FilterExtensionClient.self] = newValue }
  }
}