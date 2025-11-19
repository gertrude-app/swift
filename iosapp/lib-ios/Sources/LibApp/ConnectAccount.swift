import ComposableArchitecture
import Dependencies
import IOSRoute
import LibClients

@Reducer
public struct ConnectAccount {
  @ObservableState
  public struct State: Equatable {
    public var screen: SubScreen = .enteringCode

    public init(screen: SubScreen = .enteringCode) {
      self.screen = screen
    }
  }

  public enum Action: Equatable {
    case codeSubmitted(Int)
    case receivedConnectionError(String)
    case connectionSucceeded(childData: ChildIOSDeviceData)
    case setScreen(State.SubScreen)
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
      case .setScreen(let screen):
        state.screen = screen
        return .none
      case .receivedConnectionError(let error):
        state.screen = .connectionFailed(error: error)
        return .none
      case .connectionSucceeded(childData: let data):
        state.screen = .connected(childName: data.childName)
        return .none
      case .codeSubmitted(let code):
        state.screen = .connecting
        return .run { [deps = self.deps] send in
          guard let vendorId = await deps.device.vendorId() else {
            await send(.setScreen(.connectionFailed(error: "No vendor ID found")))
            return
          }
          do {
            let childData = try await deps.api.connectDevice(code: code, vendorId: vendorId)
            await send(.connectionSucceeded(childData: childData))
          } catch {
            await send(.setScreen(.connectionFailed(error: error.localizedDescription)))
          }
        }
      }
    }
  }

  public init() {}
}

public extension ConnectAccount.State {
  enum SubScreen: Equatable {
    case enteringCode
    case connecting
    case connectionFailed(error: String)
    case connected(childName: String)
  }
}
