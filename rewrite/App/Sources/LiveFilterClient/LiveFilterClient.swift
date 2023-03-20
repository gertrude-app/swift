import Dependencies
import Models
import NetworkExtension
import SystemExtensions

extension FilterClient: DependencyKey {
  public static var liveValue: Self {
    let manager = ThreadSafe(wrapped: FilterManager())
    return FilterClient(
      setup: { await manager.value.setup() },
      start: { await manager.value.startFilter() },
      stop: { await manager.value.stopFilter() },
      state: { await manager.value.filterState() },
      install: { await manager.value.installFilter() }
    )
  }
}
