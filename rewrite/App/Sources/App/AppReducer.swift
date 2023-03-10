import ComposableArchitecture
import MenuBar

public struct AppReducer: Reducer {
  public struct State: Equatable {
    public var menuBar = MenuBar.State()
    public init() {}
  }

  public enum Action: Equatable {
    case delegate(AppDelegateReducer.Action)
    case menuBar(MenuBar.Action)
  }

  public var body: some ReducerOf<Self> {
    Scope(state: \.menuBar, action: /Action.menuBar) {
      MenuBar()
    }
  }

  public init() {}
}
