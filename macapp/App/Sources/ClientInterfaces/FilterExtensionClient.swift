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
  public var installOverridingTimeout: @Sendable (_ timeout: Int) async -> FilterInstallResult
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
    installOverridingTimeout: @escaping @Sendable (_ timeout: Int) async -> FilterInstallResult,
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
    self.installOverridingTimeout = installOverridingTimeout
    self.stateChanges = stateChanges
    self.uninstall = uninstall
  }
}

extension FilterExtensionClient: TestDependencyKey {
  public static let testValue = Self(
    setup: unimplemented("FilterExtensionClient.setup", placeholder: .unknown),
    start: unimplemented("FilterExtensionClient.start", placeholder: .unknown),
    stop: unimplemented("FilterExtensionClient.stop", placeholder: .unknown),
    reinstall: unimplemented("FilterExtensionClient.reinstall", placeholder: .alreadyInstalled),
    restart: unimplemented("FilterExtensionClient.restart", placeholder: .unknown),
    replace: unimplemented("FilterExtensionClient.replace", placeholder: .alreadyInstalled),
    state: unimplemented("FilterExtensionClient.state", placeholder: .unknown),
    install: unimplemented("FilterExtensionClient.install", placeholder: .alreadyInstalled),
    installOverridingTimeout: unimplemented(
      "FilterExtensionClient.installOverridingTimeout",
      placeholder: .alreadyInstalled
    ),
    stateChanges: unimplemented(
      "FilterExtensionClient.stateChanges",
      placeholder: AnyPublisher(Empty())
    ),
    uninstall: unimplemented("FilterExtensionClient.uninstall", placeholder: true)
  )

  public static let mock = Self(
    setup: { .installedAndRunning },
    start: { .installedAndRunning },
    stop: { .installedButNotRunning },
    reinstall: { .installedSuccessfully },
    restart: { .installedAndRunning },
    replace: { .installedSuccessfully },
    state: { .installedAndRunning },
    install: { .installedSuccessfully },
    installOverridingTimeout: { _ in .installedSuccessfully },
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
