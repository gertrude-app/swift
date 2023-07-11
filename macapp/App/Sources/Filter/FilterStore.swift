import Combine
import Core
import Foundation
import Gertie
// import ComposableArchitecture
import SyncArch

public struct FilterStore: NetworkFilter {
  let store: Store<Filter>
  private var deps = FilterDeps.live

  // TODO: does this need to be public?
  public var state: Filter.State { store.state }

  public var security: SecurityClient {
    deps.security
  }

  public init() {
    store = Store(initialState: Filter.State(), reducer: Filter(), deps: .live)
    store.send(.extensionStarted)
  }

  public func sendBlocked(_ flow: FilterFlow, auditToken: Data?) {
    let app = appDescriptor(for: flow.bundleId ?? "(no bundle id)", auditToken: auditToken)
    store.send(.flowBlocked(flow, app))
  }

  public func shouldSendBlockDecisions() -> AnyPublisher<Bool, Never> {
    store.publisher.blockListeners.map { !$0.isEmpty }.eraseToAnyPublisher()
  }

  public func appCache(insert descriptor: AppDescriptor, for bundleId: String) {
    store.send(.cacheAppDescriptor(bundleId, descriptor))
  }

  public func appCache(get bundleId: String) -> AppDescriptor? {
    state.appCache[bundleId]
  }

  public func sendExtensionStopping() {
    store.send(.extensionStopping)
  }
}
