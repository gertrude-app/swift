import ComposableArchitecture
import Core
import Foundation
import Gertie
import MacAppRoute

struct BlockedRequestsFeature: Feature {
  struct State: Equatable, Sendable {
    var windowOpen = false
    var requests: [BlockedRequest] = []
    var selectedRequestIds: [UUID] = []
    var filterText = ""
    var tcpOnly = true
    var createUnlockRequests = RequestState<String>.idle
  }

  enum Action: Equatable, Sendable {
    enum View: Equatable, Sendable, Decodable {
      case filterTextUpdated(text: String)
      case requestFailedTryAgainClicked
      case unlockRequestSubmitted(comment: String?)
      case toggleRequestSelected(id: UUID)
      case tcpOnlyToggled
      case clearRequestsClicked
      case closeWindow
      case inactiveAccountRecheckClicked
      case inactiveAccountDisconnectAppClicked
    }

    case openWindow
    case closeWindow
    case webview(View)
    case createUnlockRequests(TaskResult<EquatableVoid>)
    case createUnlockRequestsSuccessTimedOut
  }

  private enum CancelId { case timeout }

  struct Reducer: FeatureReducer {
    @Dependency(\.api) var api
    @Dependency(\.filterXpc) var filterXpc
    @Dependency(\.mainQueue) var mainQueue

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {
      case .openWindow:
        state.windowOpen = true
        return restartBlockStreaming()

      case .webview(.inactiveAccountRecheckClicked),
           .webview(.inactiveAccountDisconnectAppClicked):
        return .none // handled by AdminFeature

      case .closeWindow, .webview(.closeWindow):
        state.windowOpen = false
        state.requests = []
        state.selectedRequestIds = []
        return endBlockStreaming()

      case .webview(.filterTextUpdated(let text)):
        state.filterText = text
        return restartBlockStreaming()

      case .webview(.tcpOnlyToggled):
        state.tcpOnly.toggle()
        return restartBlockStreaming()

      case .webview(.clearRequestsClicked):
        state.requests = []
        state.selectedRequestIds = []
        return restartBlockStreaming()

      case .webview(.requestFailedTryAgainClicked):
        if case .failed = state.createUnlockRequests {
          state.createUnlockRequests = .idle
        }
        return .none

      case .webview(.toggleRequestSelected(id: let id)):
        if state.selectedRequestIds.contains(id) {
          state.selectedRequestIds.removeAll(where: { $0 == id })
        } else {
          state.selectedRequestIds.append(id)
        }
        switch state.createUnlockRequests {
        case .succeeded, .failed:
          state.createUnlockRequests = .idle
          return .cancel(id: CancelId.timeout)
        case .idle, .ongoing:
          return .none
        }

      case .webview(.unlockRequestSubmitted(let comment)):
        state.createUnlockRequests = .ongoing
        let inputReqs = state.requests
          .filter { state.selectedRequestIds.contains($0.id) }
          .map { CreateUnlockRequests_v2.Input.BlockedRequest(
            time: $0.time,
            bundleId: $0.app.bundleId,
            url: $0.url,
            hostname: $0.hostname,
            ipAddress: $0.ipAddress
          ) }
        return .task {
          await .createUnlockRequests(TaskResult {
            try await api.createUnlockRequests(.init(blockedRequests: inputReqs, comment: comment))
          })
        }

      case .createUnlockRequests(.success):
        state.createUnlockRequests = .succeeded
        state.selectedRequestIds = []
        return .run { send in
          try await mainQueue.sleep(for: .seconds(10))
          await send(.createUnlockRequestsSuccessTimedOut)
        }.cancellable(id: CancelId.timeout, cancelInFlight: true)

      case .createUnlockRequests(.failure(let error)):
        state.createUnlockRequests = .failed(error: error.userMessage())
        return .none

      case .createUnlockRequestsSuccessTimedOut:
        if case .succeeded = state.createUnlockRequests {
          state.createUnlockRequests = .idle
        }
        return .none
      }
    }
  }

  struct RootReducer: RootReducing {
    @Dependency(\.filterXpc) var filterXpc
  }
}

extension BlockedRequestsFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Self.Action> {
    switch action {
    case .menuBar(.viewNetworkTrafficClicked):
      state.blockedRequests.windowOpen = true
      return .run { _ in
        // TODO: if not successful, log unexpected
        _ = await filterXpc.setBlockStreaming(true)
      }

    case .xpc(.receivedExtensionMessage(.blockedRequest(let request))):
      state.blockedRequests.requests.append(request)
      return .none

    default:
      return .none
    }
  }
}

extension BlockedRequestsFeature.State {
  struct View: Equatable, Encodable {
    var windowOpen = false
    var selectedRequestIds: [UUID] = []
    var requests: [Request] = []
    var filterText = ""
    var tcpOnly = false
    var createUnlockRequests = RequestState<String>.idle
    var adminAccountStatus: AdminAccountStatus = .active

    init(state: AppReducer.State) {
      windowOpen = state.blockedRequests.windowOpen
      requests = state.blockedRequests.requests.map(\.view)
      filterText = state.blockedRequests.filterText
      tcpOnly = state.blockedRequests.tcpOnly
      createUnlockRequests = state.blockedRequests.createUnlockRequests
      selectedRequestIds = state.blockedRequests.selectedRequestIds
      adminAccountStatus = state.admin.accountStatus
    }
  }
}

extension BlockedRequestsFeature.State.View {
  struct Request: Equatable, Encodable {
    var id: UUID
    var time: Date
    var target: String
    var `protocol`: IpProtocol.Kind
    var searchableText: String
    var app: String
  }
}

extension BlockedRequest {
  var view: BlockedRequestsFeature.State.View.Request {
    .init(
      id: id,
      time: time,
      target: url ?? hostname ?? ipAddress ?? "unknown",
      protocol: ipProtocol?.kind ?? .other,
      searchableText: [url, hostname, ipAddress, app.searchableText]
        .compactMap { $0 }
        .joined(separator: " "),
      app: app.displayName ?? app.bundleId
    )
  }
}

extension AppDescriptor {
  var searchableText: String {
    ([displayName, bundleId, slug] + .init(categories))
      .compactMap { $0 }
      .joined(separator: " ")
  }
}

extension BlockedRequestsFeature.Reducer {
  typealias State = BlockedRequestsFeature.State
  typealias Action = BlockedRequestsFeature.Action

  // every time the user interacts with the blocked requests window, that
  // shows they are still actively interested in the blocked requests, so
  // we restart the 5-minute expiration timer
  func restartBlockStreaming() -> Effect<Action> {
    .run { [setBlockStreaming = filterXpc.setBlockStreaming] _ in
      // probably ok to ignore error here, very unlikely to happen
      // we'll concentrate error handling for the initial window open event
      _ = await setBlockStreaming(true)
    }
  }

  func endBlockStreaming() -> Effect<Action> {
    .run { [setBlockStreaming = filterXpc.setBlockStreaming] _ in
      // ok to ignore error here, worst that can happen is streaming expires on its own
      _ = await setBlockStreaming(false)
    }
  }
}
