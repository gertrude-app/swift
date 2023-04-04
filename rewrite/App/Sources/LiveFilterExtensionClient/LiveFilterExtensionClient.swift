import Combine
import Core
import Dependencies
import Models
import NetworkExtension
import SystemExtensions

extension FilterExtensionClient: DependencyKey {
  public static var liveValue: Self {
    let manager = ThreadSafeFilterManager()
    return FilterExtensionClient(
      setup: { await manager.setup() },
      start: { await manager.startFilter() },
      stop: { await manager.stopFilter() },
      state: { await manager.loadState() },
      install: { await manager.installFilter() },
      stateChanges: {
        filterStateChanges.withValue { subject in
          Move(subject.eraseToAnyPublisher())
        }.consume()
      }
    )
  }
}

actor ThreadSafeFilterManager {
  private var manager = FilterManager()

  func setup() async -> FilterState {
    await manager.setup()
  }

  func loadState() async -> FilterState {
    await manager.loadState()
  }

  func startFilter() async -> FilterState {
    await manager.startFilter()
  }

  func stopFilter() async -> FilterState {
    await manager.stopFilter()
  }

  func installFilter() async -> FilterInstallResult {
    await manager.installFilter()
  }
}
