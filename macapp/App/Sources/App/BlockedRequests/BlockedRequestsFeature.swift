import ClientInterfaces
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
    var filterCommunicationConfirmed: Bool?
    var pendingUnlockRequests: [PendingRequest] = []
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
      case noFilterCommunicationAdministrateClicked
    }

    case closeWindow
    case webview(View)
    case createUnlockRequests(TaskResult<[UUID]>)
    case createUnlockRequestsSuccessTimedOut
    case receivedFilterCommunicationConfirmation(Bool)
  }

  private enum CancelId { case timeout }

  struct Reducer: FeatureReducer {
    @Dependency(\.api) var api
    @Dependency(\.filterXpc) var filterXpc
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.date.now) var now

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {

      case .webview(.inactiveAccountRecheckClicked),
           .webview(.inactiveAccountDisconnectAppClicked),
           .webview(.noFilterCommunicationAdministrateClicked):
        return .none // handled by AdminFeature

      case .closeWindow, .webview(.closeWindow):
        state.windowOpen = false
        state.requests = []
        state.selectedRequestIds = []
        return endBlockStreaming()

      case .receivedFilterCommunicationConfirmation(let connected):
        state.filterCommunicationConfirmed = connected
        return .none

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
          .map { CreateUnlockRequests_v3.Input.BlockedRequest(
            bundleId: $0.app.bundleId,
            url: $0.url,
            hostname: $0.hostname,
            ipAddress: $0.ipAddress
          ) }
        // shouldn't need to check network connection, a blocked request should imply connected
        return .exec { send in
          await send(.createUnlockRequests(TaskResult {
            try await self.api.createUnlockRequests(.init(
              blockedRequests: inputReqs,
              comment: comment
            ))
          }))
        }

      case .createUnlockRequests(.success(let ids)):
        state.createUnlockRequests = .succeeded
        state.pendingUnlockRequests = ids.map { .init(id: $0, createdAt: self.now) }
        state.selectedRequestIds = []
        return .exec { send in
          try await self.mainQueue.sleep(for: .seconds(10))
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
    typealias Action = AppReducer.Action
    typealias State = AppReducer.State
    @Dependency(\.filterXpc) var filterXpc
    @Dependency(\.date.now) var now
    @Dependency(\.device) var device
  }
}

extension BlockedRequestsFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Self.Action> {
    switch action {
    case .menuBar(.viewNetworkTrafficClicked):
      state.blockedRequests.windowOpen = true
      state.blockedRequests.filterCommunicationConfirmed = nil // re-test on each open
      return .exec { send in
        let connected = await filterXpc.connected(attemptRepair: true)
        await send(.blockedRequests(.receivedFilterCommunicationConfirmation(connected)))
        if !connected {
          unexpectedError(id: "46d4be97")
        } else if await (filterXpc.setBlockStreaming(true)).isFailure {
          unexpectedError(id: "f2c3b277")
        }
      }

    case .xpc(.receivedExtensionMessage(.blockedRequest(let newReq))):
      let recent = state.blockedRequests.requests.suffix(15)
      if !recent.contains(where: { existing in existing.mergeable(with: newReq) }) {
        state.blockedRequests.requests.append(newReq)
      }
      return .none

    case .websocket(.receivedMessage(.unlockRequestUpdated_v2(let id, _, _, _))):
      state.blockedRequests.pendingUnlockRequests.removeAll(where: { $0.id == id })
      return .none

    case .heartbeat(.everyMinute):
      state.blockedRequests.pendingUnlockRequests
        .removeAll(where: { $0.createdAt.advanced(by: .minutes(20)) < now })
      return .none

    case .checkIn(result: .success(let checkInResult), reason: _):
      if let unlockRequests = checkInResult.resolvedUnlockRequests {
        interestingEvent(id: "5d5360f4", "fallback poll resolved unlock requests")
        state.blockedRequests.pendingUnlockRequests.removeAll { pending in
          unlockRequests.contains { $0.id == pending.id }
        }
        guard checkInResult.resolvedFilterSuspension == nil else {
          return .none // to prioritize filter suspension notification
        }
        return .exec { _ in
          for unlockRequest in unlockRequests {
            await device.notifyUnlockRequestUpdated(
              accepted: unlockRequest.status == .accepted,
              target: unlockRequest.target,
              comment: unlockRequest.comment
            )
          }
        }
      }
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
    var filterCommunicationConfirmed: Bool?

    init(state: AppReducer.State) {
      self.windowOpen = state.blockedRequests.windowOpen
      self.requests = state.blockedRequests.requests.map(\.view)
      self.filterText = state.blockedRequests.filterText
      self.tcpOnly = state.blockedRequests.tcpOnly
      self.createUnlockRequests = state.blockedRequests.createUnlockRequests
      self.selectedRequestIds = state.blockedRequests.selectedRequestIds
      self.adminAccountStatus = state.admin.accountStatus
      self.filterCommunicationConfirmed = state.blockedRequests.filterCommunicationConfirmed
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
        .compactMap(\.self)
        .joined(separator: " "),
      app: app.displayName ?? app.bundleId
    )
  }
}

extension AppDescriptor {
  var searchableText: String {
    ([displayName, bundleId, slug] + .init(categories))
      .compactMap(\.self)
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
    .exec { [setBlockStreaming = filterXpc.setBlockStreaming] _ in
      // probably ok to ignore error here, very unlikely to happen
      // we'll concentrate error handling for the initial window open event
      _ = await setBlockStreaming(true)
    }
  }

  func endBlockStreaming() -> Effect<Action> {
    .exec { [setBlockStreaming = filterXpc.setBlockStreaming] _ in
      // ok to ignore error here, worst that can happen is streaming expires on its own
      _ = await setBlockStreaming(false)
    }
  }
}
