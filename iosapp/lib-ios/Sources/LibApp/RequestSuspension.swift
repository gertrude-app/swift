import ComposableArchitecture
import TaggedTime

@Reducer
public struct RequestSuspension {
  @ObservableState
  public enum State: Equatable {
    case customizing
    case requesting
    case requestFailed(error: String)
    case waitingForDecision
    case denied(comment: String?)
    case granted(duration: Seconds<Int>, comment: String?)
    case suspended
  }

  public enum Action: Equatable {
    case submitRequest(duration: Seconds<Int>, comment: String?)
    case requestSucceeded(UUID)
    case setState(State)
    case startSuspensionTapped(Seconds<Int>)
  }

  struct Deps: Sendable {
    @Dependency(\.api) var api
    @Dependency(\.device) var device
  }

  @ObservationIgnored
  let deps = Deps()

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .setState(let newState):
        state = newState
        return .none
      case .requestSucceeded:
        state = .waitingForDecision
        return .none
      case .submitRequest(let duration, let comment):
        state = .requesting
        return .run { [deps = self.deps] send in
          do {
            let id = try await deps.api.createSuspendFilterRequest(
              duration: duration,
              comment: comment
            )
            await send(.requestSucceeded(id))
          } catch {
            await send(.setState(.requestFailed(error: error.localizedDescription)))
          }
        }
      case .startSuspensionTapped:
        return .none
      }
    }
  }
}
