import Foundation
import Gertie
import NIOWebSocket
import Tagged
import Vapor
import XCore

class AppConnection {
  struct Ids {
    let userDevice: UserDevice.Id
    let user: User.Id
    let keychains: [Keychain.Id]
  }

  let id: Id
  let ids: Ids
  let ws: WebsocketProtocol
  var filterState: UserFilterState?

  init(ws: WebsocketProtocol, ids: Ids) {
    self.id = .init(UUID())
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
    guard let message = try? JSON.decode(json, as: IncomingMessage.self) else {
      Current.logger.error("WS: failed to decode WebSocket message: `\(json)`")
      return
    }
    Current.logger.notice("WS: WebSocket \(self.id.lowercased) got message: \(message)")
    switch message {
    case .currentFilterState(let filterState):
      self.filterState = filterState
    case .goingOffline:
      Task { await Current.connectedApps.remove(self) }
    }
  }
}

extension AppConnection {
  typealias Id = Tagged<AppConnection, UUID>
  typealias IncomingMessage = WebSocketMessage.FromAppToApi
}
