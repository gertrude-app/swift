import ComposableArchitecture

public struct FilterStore {
  let store = Store(initialState: Filter.State(), reducer: Filter())
  let viewStore: ViewStore<Void, Filter.Action>

  public init() {
    viewStore = ViewStore(store.stateless)
    viewStore.send(.extensionStarted)
  }
}
