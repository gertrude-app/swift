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

  enum FilterStateData {
    case withoutTimes(FilterState.WithoutTimes)
    case withTimes(FilterState.WithTimes)
  }

  let id: Id
  let ids: Ids
  let ws: WebSocket
  var filterState: FilterStateData?

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
    case .currentFilterState(let filterStateWithoutTimes):
      self.filterState = .withoutTimes(filterStateWithoutTimes)
    case .currentFilterState_v2(let filterState):
      self.filterState = .withTimes(filterState)
    case .goingOffline:
      Task { await with(dependency: \.websockets).remove(self) }
    }
  }
}

// NB: `nil` the dates while still supporting < `v2.7.0`
extension FilterState.WithoutTimes {
  var status: ChildComputerStatus {
    switch self {
    case .off:
      .filterOff
    case .on:
      .filterOn
    case .suspended:
      .filterSuspended(resuming: nil)
    case .downtime:
      .downtime(ending: nil)
    case .downtimePaused:
      .downtimePaused(resuming: nil)
    }
  }
}

extension FilterState.WithTimes {
  var status: ChildComputerStatus {
    switch self {
    case .off:
      .filterOff
    case .on:
      .filterOn
    case .suspended(let resuming):
      .filterSuspended(resuming: resuming)
    case .downtime(let ending):
      .downtime(ending: ending)
    case .downtimePaused(let resuming):
      .downtimePaused(resuming: resuming)
    }
  }
}

extension AppConnection {
  typealias Id = Tagged<AppConnection, UUID>
  typealias IncomingMessage = WebSocketMessage.FromAppToApi
}
