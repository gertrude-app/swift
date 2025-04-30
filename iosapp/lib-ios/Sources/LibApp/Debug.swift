import ComposableArchitecture

@Reducer
public struct Debug {
  @ObservableState
  public struct State: Equatable {
    public var vendorId: UUID?
    public var timesShaken: Int = 0
  }

  public enum Action: Equatable {
    case placeholder
  }

  struct Deps: Sendable {
    @Dependency(\.api) var api
    @Dependency(\.device) var device
  }

  @ObservationIgnored
  let deps = Deps()

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      .none
    }
  }
}
