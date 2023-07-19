import Combine
import Core
import Dependencies

public struct FilterExtensionClient: Sendable {
  public var setup: @Sendable () async -> FilterExtensionState
  public var start: @Sendable () async -> FilterExtensionState
  public var stop: @Sendable () async -> FilterExtensionState
  public var reinstall: @Sendable () async -> FilterInstallResult
  public var restart: @Sendable () async -> FilterExtensionState
  public var replace: @Sendable () async -> FilterInstallResult
  public var state: @Sendable () async -> FilterExtensionState
  public var install: @Sendable () async -> FilterInstallResult
  public var stateChanges: @Sendable () -> AnyPublisher<FilterExtensionState, Never>
  public var uninstall: @Sendable () async -> Bool

  public init(
    setup: @escaping @Sendable () async -> FilterExtensionState,
    start: @escaping @Sendable () async -> FilterExtensionState,
    stop: @escaping @Sendable () async -> FilterExtensionState,
    reinstall: @escaping @Sendable () async -> FilterInstallResult,
    restart: @escaping @Sendable () async -> FilterExtensionState,
    replace: @escaping @Sendable () async -> FilterInstallResult,
    state: @escaping @Sendable () async -> FilterExtensionState,
    install: @escaping @Sendable () async -> FilterInstallResult,
    stateChanges: @escaping @Sendable () -> AnyPublisher<FilterExtensionState, Never>,
    uninstall: @escaping @Sendable () async -> Bool
  ) {
    self.setup = setup
    self.start = start
    self.stop = stop
    self.reinstall = reinstall
    self.restart = restart
    self.replace = replace
    self.state = state
    self.install = install
    self.stateChanges = stateChanges
    self.uninstall = uninstall
  }
}

extension FilterExtensionClient: TestDependencyKey {
  public static let testValue = Self(
    setup: { .installedAndRunning },
    start: { .installedAndRunning },
    stop: { .installedButNotRunning },
    reinstall: { .installedSuccessfully },
    restart: { .installedAndRunning },
    replace: { .installedSuccessfully },
    state: { .installedAndRunning },
    install: { .installedSuccessfully },
    stateChanges: { Empty().eraseToAnyPublisher() },
    uninstall: { true }
  )
}

public extension DependencyValues {
  var filterExtension: FilterExtensionClient {
    get { self[FilterExtensionClient.self] }
    set { self[FilterExtensionClient.self] = newValue }
  }
}
