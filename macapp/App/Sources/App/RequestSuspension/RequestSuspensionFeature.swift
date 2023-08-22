import ClientInterfaces
import ComposableArchitecture
import Gertie

struct RequestSuspensionFeature: Feature {
  struct State: Equatable, Encodable {
    var windowOpen = false
    var request = RequestState<String>.idle
    var adminAccountStatus: AdminAccountStatus = .active
    var filterCommunicationConfirmed: Bool?

    struct View: Equatable, Codable {
      var windowOpen: Bool
      var request: RequestState<String>
      var adminAccountStatus: AdminAccountStatus
      var internetConnected: Bool
      var filterCommunicationConfirmed: Bool?
    }
  }

  enum Action: Equatable, Sendable {
    enum View: Equatable, Decodable {
      case closeWindow
      case requestSubmitted(durationInSeconds: Int, comment: String?)
      case requestFailedTryAgainClicked
      case inactiveAccountRecheckClicked
      case inactiveAccountDisconnectAppClicked
      case grantSuspensionClicked(durationInSeconds: Int)
      case noFilterCommunicationAdministrateClicked
    }

    case webview(View)
    case closeWindow
    case createSuspensionRequest(TaskResult<EquatableVoid>)
    case createSuspensionRequestSuccessTimedOut
    case receivedFilterCommunicationConfirmation(Bool)
  }

  private enum CancelId { case successTimeout }

  struct Reducer: FeatureReducer {
    @Dependency(\.api) var api
    @Dependency(\.backgroundQueue) var bgQueue

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {

      case .webview(.inactiveAccountRecheckClicked),
           .webview(.inactiveAccountDisconnectAppClicked),
           .webview(.noFilterCommunicationAdministrateClicked):
        return .none // handled by AdminFeature

      case .receivedFilterCommunicationConfirmation(let confirmed):
        state.filterCommunicationConfirmed = confirmed
        return .none

      case .webview(.closeWindow), .closeWindow:
        state.windowOpen = false
        return .none

      case .webview(.requestFailedTryAgainClicked):
        state.request = .idle
        return .cancel(id: CancelId.successTimeout)

      case .webview(.requestSubmitted(let durationInSeconds, let comment)):
        return .exec { send in
          await send(.createSuspensionRequest(TaskResult {
            try await api.createSuspendFilterRequest(.init(
              duration: durationInSeconds,
              comment: comment
            ))
          }))
        }

      case .webview(.grantSuspensionClicked):
        return .none // handled by root reducer

      case .createSuspensionRequest(.success):
        state.request = .succeeded
        return .exec { send in
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

  struct RootReducer: AdminAuthenticating {
    @Dependency(\.filterXpc) var filterXpc
    @Dependency(\.security) var security
  }
}

extension RequestSuspensionFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Self.Action> {
    switch action {
    case .menuBar(.suspendFilterClicked):
      state.requestSuspension.filterCommunicationConfirmed = nil
      state.requestSuspension.windowOpen = true
      return .exec { send in
        let connected = await filterXpc.connected(attemptRepair: true)
        await send(.requestSuspension(.receivedFilterCommunicationConfirmation(connected)))
        if !connected { unexpectedError(id: "9ed77176") }
      }

    case .requestSuspension(.webview(.grantSuspensionClicked)):
      return adminAuthenticated(action)

    default:
      return .none
    }
  }
}

extension RequestSuspensionFeature.State.View {
  init(_ state: AppReducer.State) {
    @Dependency(\.network) var network
    windowOpen = state.requestSuspension.windowOpen
    request = state.requestSuspension.request
    adminAccountStatus = state.admin.accountStatus
    internetConnected = network.isConnected()
    filterCommunicationConfirmed = state.requestSuspension.filterCommunicationConfirmed
  }
}
