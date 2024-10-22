import Foundation
import Gertie
import NIOWebSocket
import Tagged
import Vapor
import XCore

actor AppConnection {
  struct Ids {
    let userDevice: UserDevice.Id
    let user: User.Id
    let keychains: [Keychain.Id]
  }

  let id: Id
  let ids: Ids
  let ws: WebSocket
  var filterState: FilterState.WithoutTimes?

  init(ws: WebSocket, ids: Ids) {
    self.id = .init(UUID())
    self.ids = ids
    self.ws = ws
    self.ws.onText { ws, string in
      await self.onText(ws, string)
    }
    self.ws.onClose.whenComplete { result in
      switch result {
      case .success:
        Task { await with(dependency: \.websockets).remove(self) }
      case .failure:
        break
      }
    }
  }

  func onText(_ ws: WebsocketProtocol, _ json: String) {
    guard let message = try? JSON.decode(json, as: IncomingMessage.self) else {
      with(dependency: \.logger)
        .error("WS: failed to decode WebSocket message: `\(json)`")
      return
    }
    with(dependency: \.logger)
      .notice("WS: WebSocket \(self.id.lowercased) got message: \(message)")
    switch message {
    case .currentFilterState(let filterState):
      self.filterState = filterState
    case .goingOffline:
      Task { await with(dependency: \.websockets).remove(self) }
    }
  }
}

extension AppConnection {
  typealias Id = Tagged<AppConnection, UUID>
  typealias IncomingMessage = WebSocketMessage.FromAppToApi
}
