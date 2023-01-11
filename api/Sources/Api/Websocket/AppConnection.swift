import Foundation
import NIOWebSocket
import Shared
import Tagged
import Vapor
import XCore

class AppConnection {
  typealias Id = Tagged<AppConnection, UUID>
  typealias IncomingMessage = WebsocketMsg.AppToApi.Message

  struct Ids {
    let device: Device.Id
    let user: User.Id
    let keychains: [Keychain.Id]
  }

  let id: Id
  let ids: Ids
  let ws: WebSocketProtocol
  var filterState: FilterState?

  init(ws: WebSocketProtocol, ids: Ids) {
    id = .init(UUID())
    self.ids = ids
    self.ws = ws

    ws.onText { ws, string in
      self.onText(ws, string)
    }

    ws.onClose.whenComplete { result in
      Current.logger.notice("WS: closed with result \(result)")
      switch result {
      case .success:
        AppConnections.shared.remove(self)
      case .failure:
        break
      }
    }
  }

  func onText(_ ws: WebSocketProtocol, _ json: String) {
    Current.logger.notice("WS: WebSocket \(id) got a message: `\(json)`")
    guard let msg = try? JSON.decode(json, as: IncomingMessage.self) else {
      Current.logger.error("WS: failed to decode message type from WebSocket msg: `\(json)`")
      return
    }
    switch msg.type {
    case .currentFilterState:
      guard let currentFilter = try? JSON.decode(json, as: IncomingMessage.CurrentFilterState.self)
      else {
        Current.logger.error("WS: failed to decode CurrentFilterStatus from msg: `\(json)`")
        return
      }
      filterState = currentFilter.state
      Current.logger.notice(
        "WS: received current filter state \(currentFilter) from \(ids.device)"
      )
    }
  }
}

protocol WebSocketProtocol {
  func onText(_ callback: @escaping (Self, String) async -> Void)
  func close(code: WebSocketErrorCode) async throws
  func close(code: WebSocketErrorCode) -> EventLoopFuture<Void>
  var onClose: EventLoopFuture<Void> { get }
  var isClosed: Bool { get }
  func send<S>(_ text: S) async throws
    where S: Collection, S.Element == Character
  func send<T: Codable>(_ msg: T) throws
}

extension WebSocket: WebSocketProtocol {}

extension WebSocketProtocol {
  func send<T: Codable>(_ msg: T) throws {
    try send(try JSON.encode(msg))
  }
}
