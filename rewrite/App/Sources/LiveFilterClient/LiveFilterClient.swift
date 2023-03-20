import Dependencies
import Models
import NetworkExtension
import SystemExtensions

extension FilterClient: DependencyKey {
  public static var liveValue: Self {
    let manager = ThreadSafe(wrapped: FilterManager())
    return FilterClient(
      setup: { await manager.value.setup() },
      start: { fatalError() },
      state: { manager.value.filterState() },
      install: { try await manager.value.installFilter() }
    )
  }
}
