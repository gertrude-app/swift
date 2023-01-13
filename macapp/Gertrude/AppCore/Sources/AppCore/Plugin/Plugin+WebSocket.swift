import Foundation
import Shared
import SharedCore
import Starscream
import Websocket
import XCore

class WebSocketPlugin: Plugin {
  private var store: AppStore
  private var connection: WebsocketConnection

  init(store: AppStore) {
    self.store = store
    connection = createConnection(store)
    attachHandlers(connection)

    afterDelayOf(seconds: 2) { [weak self] in
      guard let self = self else { return }
      self.connection.shouldRepairConnection = self.store.state.hasUserToken
    }
  }

  func attachHandlers(_ connection: WebsocketConnection) {
    connection.handleIncomingMessage = { [weak self] in self?.receiveApiMessage($0) }
    connection.log = { [weak self] in self?.logMsg($0) }
    connection.logError = { [weak self] in self?.logError($0) }
  }

  func receiveApiMessage(_ json: String) {
    log(.plugin("Websocket", .level(.info, "received API message", .json(json))))
    guard let message = try? JSON.decode(json, as: IncomingMessage.self) else {
      log(.decodeError(IncomingMessage.self, json))
      return
    }

    switch message.type {
    case .requestFilterState:
      sendCurrentFilterState()
    case .userUpdated:
      store.send(.receivedWebsocketMessageUserUpdated)
    case .unlockRequestUpdated:
      handleUnlockRequestUpdated(json)
    case .suspendFilterRequestDenied:
      handleSuspendFilterRequestDenied(json)
    case .suspendFilter:
      handleSuspendFilter(json)
    }
  }

  func handleSuspendFilter(_ json: String) {
    guard let msg = try? JSON.decode(json, as: IncomingMessage.SuspendFilter.self) else {
      log(.decodeError(IncomingMessage.SuspendFilter.self, json))
      return
    }

    guard let humanTime = msg.suspension.duration.rawValue.futureHumanTime else {
      return
    }

    store.send(.receivedFilterSuspension(msg.suspension))
    store.send(.emitAppEvent(.suspendFilter(msg.suspension)))

    let title = "🟠 Temporarily disabling filter"
    let body: String
    if let comment = msg.comment, !comment.isEmpty {
      body = "Parent comment: \"\(comment)\"\nFilter suspended, resuming \(humanTime)"
    } else {
      body = "Filter will resume normal blocking in \(humanTime)"
    }
    store.send(.emitAppEvent(.showNotification(title: title, body: body)))
  }

  func handleSuspendFilterRequestDenied(_ json: String) {
    guard let deny = try? JSON.decode(json, as: IncomingMessage.SuspendFilterRequestDenied.self) else {
      log(.decodeError(IncomingMessage.SuspendFilterRequestDenied.self, json))
      return
    }

    let title = "⛔️ Suspend filter request DENIED"
    var body: [String] = []
    if let responseComment = deny.responseComment {
      body.append("Parent comment: \"\(responseComment)\"")
    }
    if let requestComment = deny.requestComment {
      body.append("Your comment: \"\(requestComment)\"")
    }

    store.send(.emitAppEvent(.showNotification(title: title, body: body.joined(separator: "\n"))))
  }

  func handleUnlockRequestUpdated(_ json: String) {
    guard let unlockMsg = try? JSON.decode(json, as: IncomingMessage.UnlockRequestUpdated.self) else {
      log(.decodeError(IncomingMessage.UnlockRequestUpdated.self, json))
      return
    }

    let accepted = unlockMsg.status == .accepted
    let title = "\(accepted ? "🔓" : "🔒") Unlock request \(accepted ? "ACCEPTED" : "REJECTED")"

    var body = "Requested address: \(unlockMsg.target)"
    if let responseComment = unlockMsg.responseComment, !responseComment.isEmpty {
      body += "\nParent comment: \"\(responseComment)\""
    }
    if let comment = unlockMsg.comment, !comment.isEmpty {
      body += "\nYour comment: \"\(comment)\""
    }

    store.send(.emitAppEvent(.showNotification(title: title, body: body)))
  }

  func respond(to event: AppEvent) {
    switch event {
    case .userTokenChanged:
      connection.shouldRepairConnection = store.state.hasUserToken
      connection.reconnect()
    case .filterStatusChanged:
      sendCurrentFilterState()
    case .appWillSleep:
      connection.disconnect()
    case .appDidWake:
      connection.reconnect()
    case .receivedNewAccountStatus(let status):
      connection.shouldRepairConnection = status != .inactive
      status == .inactive ? connection.disconnect() : connection.reconnect()
    case .websocketEndpointChanged:
      connection.disconnect()
      connection = createConnection(store)
      attachHandlers(connection)
    default:
      break
    }
  }

  func sendCurrentFilterState() {
    connection.send(OutgoingMessage.CurrentFilterState(store.state.filterState))
  }

  func onTerminate() {
    connection.disconnect()
  }

  func logMsg(_ msg: String) {
    log(.plugin("Websocket", .level(.info, "received message", .primary(msg))))
  }

  func logError(_ msg: String) {
    log(.plugin("Websocket", .level(.error, "received error", .primary(msg))))
  }
}

private func createConnection(_ store: AppStore) -> WebsocketConnection {
  WebsocketConnection { [weak store] in
    var request = URLRequest(
      url: Current.deviceStorage
        .getURL(.websocketEndpointOverride) ?? SharedConstants.WEBSOCKET_ENDPOINT
    )
    let token = store?.state.userToken?.uuidString ?? "websocket-no-user-token"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    return WebSocket(request: request)
  }
}
