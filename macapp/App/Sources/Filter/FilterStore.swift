import Combine
import ComposableArchitecture
import Core
import Foundation
import Gertie

public struct FilterStore: NetworkFilter {
  let store: StoreOf<Filter>
  let viewStore: ViewStoreOf<Filter>

  public var state: Filter.State { self.viewStore.state }

  @Dependency(\.security) public var security
  @Dependency(\.date.now) public var now
  @Dependency(\.calendar) public var calendar

  public init() {
    self.store = Store(initialState: Filter.State(), reducer: { Filter() })
    self.viewStore = ViewStore(self.store, observe: { $0 })
    self.viewStore.send(.extensionStarted)
  }

  public func sendBlocked(_ flow: FilterFlow, auditToken: Data?) {
    let app = appDescriptor(for: flow.bundleId ?? "(no bundle id)", auditToken: auditToken)
    self.viewStore.send(.flowBlocked(flow, app))
  }

  public func shouldSendBlockDecisions() -> AnyPublisher<Bool, Never> {
    self.viewStore.publisher.blockListeners.map { !$0.isEmpty }.eraseToAnyPublisher()
  }

  public func appCache(insert descriptor: AppDescriptor, for bundleId: String) {
    self.viewStore.send(.cacheAppDescriptor(bundleId, descriptor))
  }

  public func appCache(get bundleId: String) -> AppDescriptor? {
    self.state.appCache[bundleId]
  }

  public func logAppRequest(from bundleId: String?) {
    if let bundleId {
      self.viewStore.send(.logAppRequest(bundleId))
    }
  }

  public func log(event: FilterLogs.Event) {
    self.viewStore.send(.logEvent(event))
  }

  public func sendExtensionStopping() {
    self.viewStore.send(.extensionStopping)
  }
}
