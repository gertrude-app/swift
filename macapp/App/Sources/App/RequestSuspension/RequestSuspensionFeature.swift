import ClientInterfaces
import ComposableArchitecture
import Foundation
import Gertie

struct RequestSuspensionFeature: Feature {
  struct State: Equatable, Encodable {
    var windowOpen = false
    var request = RequestState<String>.idle
    var adminAccountStatus: AdminAccountStatus = .active
    var filterCommunicationConfirmed: Bool?
    var pending: PendingRequest?

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
    case createSuspensionRequest(TaskResult<UUID>)
    case createSuspensionRequestSuccessTimedOut
    case receivedFilterCommunicationConfirmation(Bool)
  }

  enum CancelId { case successTimeout }

  struct Reducer: FeatureReducer {
    @Dependency(\.api) var api
    @Dependency(\.backgroundQueue) var bgQueue
    @Dependency(\.date.now) var now

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
        state.request = .ongoing
        return .exec { send in
          await send(.createSuspensionRequest(TaskResult {
            try await self.api.createSuspendFilterRequest(.init(
              duration: durationInSeconds,
              comment: comment,
            ))
          }))
        }

      case .createSuspensionRequest(.success(let id)):
        state.request = .succeeded
        state.pending = .init(id: id, createdAt: self.now)
        return .exec { send in
          try await self.bgQueue.sleep(for: .seconds(10))
          await send(.createSuspensionRequestSuccessTimedOut)
        }.cancellable(id: CancelId.successTimeout, cancelInFlight: true)

      case .createSuspensionRequest(.failure(let error)):
        state.request = .failed(error: error.userMessage())
        return .none

      case .createSuspensionRequestSuccessTimedOut:
        state.request = .idle
        state.windowOpen = false
        return .none

      case .webview(.grantSuspensionClicked):
        return .none // handled by root reducer
      }
    }
  }

  struct RootReducer: AdminAuthenticating {
    typealias Action = AppReducer.Action
    typealias State = AppReducer.State
    @Dependency(\.filterXpc) var filterXpc
    @Dependency(\.security) var security
    @Dependency(\.date.now) var now
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

    case .websocket(.receivedMessage(.filterSuspensionRequestDecided_v2)):
      state.requestSuspension.pending = nil
      return .none

    case .heartbeat(.everyMinute):
      if state.requestSuspension.pending
        .map({ $0.createdAt.advanced(by: .minutes(10)) < now }) == true {
        state.requestSuspension.pending = nil
      }
      return .none

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
