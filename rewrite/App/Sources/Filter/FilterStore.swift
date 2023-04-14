import ComposableArchitecture
import Foundation

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
}
