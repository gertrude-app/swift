import Combine
import Core
import Dependencies

public struct FilterExtensionClient: Sendable {
  public var setup: @Sendable () async -> FilterExtensionState
  public var start: @Sendable () async -> FilterExtensionState
  public var stop: @Sendable () async -> FilterExtensionState
  public var restart: @Sendable () async -> FilterExtensionState
  public var replace: @Sendable () async -> FilterInstallResult
  public var state: @Sendable () async -> FilterExtensionState
  public var install: @Sendable () async -> FilterInstallResult
  public var stateChanges: @Sendable () -> AnyPublisher<FilterExtensionState, Never>

  public init(
    setup: @escaping @Sendable () async -> FilterExtensionState,
    start: @escaping @Sendable () async -> FilterExtensionState,
    stop: @escaping @Sendable () async -> FilterExtensionState,
    restart: @escaping @Sendable () async -> FilterExtensionState,
    replace: @escaping @Sendable () async -> FilterInstallResult,
    state: @escaping @Sendable () async -> FilterExtensionState,
    install: @escaping @Sendable () async -> FilterInstallResult,
    stateChanges: @escaping @Sendable () -> AnyPublisher<FilterExtensionState, Never>
  ) {
    self.setup = setup
    self.start = start
    self.stop = stop
    self.restart = restart
    self.replace = replace
    self.state = state
    self.install = install
    self.stateChanges = stateChanges
  }
}

extension FilterExtensionClient: TestDependencyKey {
  public static let testValue = Self(
    setup: { .installedAndRunning },
    start: { .installedAndRunning },
    stop: { .installedButNotRunning },
    restart: { .installedAndRunning },
    replace: { .installedSuccessfully },
    state: { .installedAndRunning },
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
