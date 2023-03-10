
public extension FilterState {
  var menuBar: MenuBar.State.FilterState {
    switch self {
    case .unknown, .notInstalled, .off:
      return .off
    case .on:
      return .on
    case .suspended(let resuming):
      return .suspended(expiration: "\(resuming)") // todo
    }
  }
}

public extension AppReducer.State {
  var menuBar: MenuBar.State {
    get {
      MenuBar.State(connection: connection, filterState: filter.menuBar)
    }
    set {}
  }
}
