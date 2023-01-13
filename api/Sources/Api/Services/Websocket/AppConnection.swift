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
  let ws: WebsocketProtocol
  var filterState: FilterState?

  init(ws: WebsocketProtocol, ids: Ids) {
    id = .init(UUID())
    self.ids = ids
    self.ws = ws
    ws.onText { ws, string in
      self.onText(ws, string)
    }

    ws.onClose.whenComplete { result in
      Current.logger.debug("WS: closed with result \(result)")
      switch result {
      case .success:
        Task { await Current.connectedApps.remove(self) }
      case .failure:
        break
      }
    }
  }

  func onText(_ ws: WebsocketProtocol, _ json: String) {
    Current.logger.debug("WS: WebSocket \(id) got a message: `\(json)`")
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
      Current.logger.debug(
        "WS: received current filter state \(currentFilter) from \(ids.device)"
      )
    }
  }
}
