import ComposableArchitecture
import Gertie

struct RequestSuspensionFeature: Feature {
  struct State: Equatable, Encodable {
    var windowOpen = false
    var request = RequestState<String>.idle
    var adminAccountStatus: AdminAccountStatus = .active
  }

  enum Action: Equatable, Sendable {
    enum View: Equatable, Decodable {
      case closeWindow
      case requestSubmitted(durationInSeconds: Int, comment: String?)
      case requestFailedTryAgainClicked
      case inactiveAccountRecheckClicked
      case inactiveAccountDisconnectAppClicked
    }

    case webview(View)
    case closeWindow
    case createSuspensionRequest(TaskResult<EquatableVoid>)
    case createSuspensionRequestSuccessTimedOut
  }

  private enum CancelId { case successTimeout }

  struct Reducer: FeatureReducer {
    @Dependency(\.api) var api
    @Dependency(\.backgroundQueue) var bgQueue

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {

      case .webview(.inactiveAccountRecheckClicked),
           .webview(.inactiveAccountDisconnectAppClicked):
        return .none // handled by AdminFeature

      case .webview(.closeWindow), .closeWindow:
        state.windowOpen = false
        return .none

      case .webview(.requestFailedTryAgainClicked):
        state.request = .idle
        return .cancel(id: CancelId.successTimeout)

      case .webview(.requestSubmitted(let durationInSeconds, let comment)):
        return .task {
          await .createSuspensionRequest(TaskResult {
            try await api.createSuspendFilterRequest(.init(
              duration: durationInSeconds,
              comment: comment
            ))
          })
        }

      case .createSuspensionRequest(.success):
        state.request = .succeeded
        return .run { send in
          try await bgQueue.sleep(for: .seconds(10))
          await send(.createSuspensionRequestSuccessTimedOut)
        }.cancellable(id: CancelId.successTimeout, cancelInFlight: true)

      case .createSuspensionRequest(.failure(let error)):
        state.request = .failed(error: error.userMessage())
        return .none

      case .createSuspensionRequestSuccessTimedOut:
        state.request = .idle
        state.windowOpen = false
        return .none
      }
    }
  }

  struct RootReducer: RootReducing {}
}

extension RequestSuspensionFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Self.Action> {
    switch action {
    case .menuBar(.suspendFilterClicked):
      state.requestSuspension.windowOpen = true
      return .none
    default:
      return .none
    }
  }
}

extension RequestSuspensionFeature.State {
  init(_ state: AppReducer.State) {
    windowOpen = state.requestSuspension.windowOpen
    request = state.requestSuspension.request
    adminAccountStatus = state.admin.accountStatus
  }
}
