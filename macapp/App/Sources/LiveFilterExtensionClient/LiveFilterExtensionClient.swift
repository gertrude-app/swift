import ClientInterfaces
import Combine
import Core
import Dependencies
import NetworkExtension
import SystemExtensions

extension FilterExtensionClient: DependencyKey {
  public static var liveValue: Self {
    let manager = ThreadSafeFilterManager()
    return FilterExtensionClient(
      setup: { await manager.setup() },
      start: { await manager.startFilter() },
      stop: { await manager.stopFilter() },
      restart: {
        _ = await manager.stopFilter()
        return await manager.startFilter()
      },
      replace: { await manager.replaceFilter() },
      state: { await manager.loadState() },
      install: { await manager.installFilter() },
      stateChanges: {
        filterStateChanges.withValue { subject in
          Move(subject.eraseToAnyPublisher())
        }.consume()
      },
      uninstall: { await manager.uninstallFilter() }
    )
  }
}

actor ThreadSafeFilterManager {
  private var manager = FilterManager()

  func setup() async -> FilterExtensionState {
    await manager.setup()
  }

  func loadState() async -> FilterExtensionState {
    await manager.loadState()
  }

  func startFilter() async -> FilterExtensionState {
    await manager.startFilter()
  }

  func stopFilter() async -> FilterExtensionState {
    await manager.stopFilter()
  }

  func replaceFilter() async -> FilterInstallResult {
    await manager.replaceFilter()
  }

  func installFilter() async -> FilterInstallResult {
    await manager.installFilter()
  }

  func uninstallFilter() async -> Bool {
    await manager.uninstallFilter()
  }
}