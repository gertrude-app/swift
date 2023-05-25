import Combine
import ComposableArchitecture
import Core
import Foundation
import Gertie

public struct FilterStore: NetworkFilter {
  let store: StoreOf<Filter>
  let viewStore: ViewStoreOf<Filter>

  public var state: Filter.State { viewStore.state }

  @Dependency(\.security) public var security

  public init() {
    store = Store(initialState: Filter.State(), reducer: Filter())
    viewStore = ViewStore(store, observe: { $0 })
    viewStore.send(.extensionStarted)
  }

  public func sendBlocked(_ flow: FilterFlow, auditToken: Data?) {
    let app = appDescriptor(for: flow.bundleId ?? "(no bundle id)", auditToken: auditToken)
    viewStore.send(.flowBlocked(flow, app))
  }

  public func shouldSendBlockDecisions() -> AnyPublisher<Bool, Never> {
    viewStore.publisher.blockListeners.map { !$0.isEmpty }.eraseToAnyPublisher()
  }

  public func appCache(insert descriptor: AppDescriptor, for bundleId: String) {
    viewStore.send(.cacheAppDescriptor(bundleId, descriptor))
  }

  public func appCache(get bundleId: String) -> AppDescriptor? {
    state.appCache[bundleId]
  }

  public func sendExtensionStopping() {
    viewStore.send(.extensionStopping)
  }
}
