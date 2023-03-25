import Core
import Dependencies
import Models
import NetworkExtension
import SystemExtensions

extension FilterExtensionClient: DependencyKey {
  public static var liveValue: Self {
    let manager = ThreadSafe(FilterManager())
    return FilterExtensionClient(
      setup: { await manager.value.loadState() },
      start: { await manager.value.startFilter() },
      stop: { await manager.value.stopFilter() },
      state: { await manager.value.loadState() },
      install: { await manager.value.installFilter() },
      stateChanges: { manager.value.stateChanges() }
    )
  }
}
