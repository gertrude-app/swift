import ClientInterfaces
import Combine
import Core
import Dependencies
import NetworkExtension
import SystemExtensions

extension FilterExtensionClient: @retroactive DependencyKey {
  public static var liveValue: Self {
    let manager = ThreadSafeFilterManager()
    return FilterExtensionClient(
      setup: { await manager.setup() },
      start: { await manager.startFilter() },
      stop: { await manager.stopFilter() },
      reinstall: { await manager.reinstallFilter() },
      restart: {
        _ = await manager.stopFilter()
        return await manager.startFilter()
      },
      replace: { await manager.replaceFilter() },
      state: { await manager.loadState() },
      install: { await manager.installFilter() },
      installOverridingTimeout: { await manager.installFilter(timeout: $0) },
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
    await self.manager.setup()
  }

  func loadState() async -> FilterExtensionState {
    await self.manager.loadState()
  }

  func startFilter() async -> FilterExtensionState {
    await self.manager.startFilter()
  }

  func stopFilter() async -> FilterExtensionState {
    await self.manager.stopFilter()
  }

  func replaceFilter() async -> FilterInstallResult {
    await self.manager.replaceFilter()
  }

  func installFilter(timeout: Int? = nil) async -> FilterInstallResult {
    await self.manager.installFilter(timeout: timeout)
  }

  func uninstallFilter() async -> Bool {
    await self.manager.uninstallFilter()
  }

  func reinstallFilter() async -> FilterInstallResult {
    await self.manager.reinstallFilter()
  }
}
