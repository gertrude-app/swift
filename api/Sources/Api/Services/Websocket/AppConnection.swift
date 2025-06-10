import Foundation
import Gertie
import NIOWebSocket
import Tagged
import Vapor
import XCore

final class AppConnection: Sendable {
  struct Ids: Sendable {
    let computerUser: ComputerUser.Id
    let child: Child.Id
    let keychains: [Keychain.Id]
  }

  enum FilterStateData: Sendable {
    case withoutTimes(FilterState.WithoutTimes)
    case withTimes(FilterState.WithTimes)
  }

  let id: Id
  let ids: Ids
  let ws: WebSocket
  let filterState: Mutex<FilterStateData?> = Mutex(nil)
  let lastActivity = Mutex(Date())

  init(ws: WebSocket, ids: Ids) {
    self.id = .init(UUID())
    self.ids = ids
    self.ws = ws
    // https://github.com/vapor/websocket-kit/issues/139
    self.ws.eventLoop.execute {
      self.ws.onText { _, text in self.onText(text) }
      self.ws.onPing { _, _ in self.onPing() }
      self.ws.onClose.whenComplete { result in
        switch result {
        case .success:
          self.log("onclose success")
          Task { await with(dependency: \.websockets).remove(self) }
        case .failure(let err):
          self.log("onclose fail", extra: "err: \(err)")
        }
      }
    }
  }

  func log(_ primary: String, extra: String? = nil) {
    var childMsg = "[WS] child=\(self.ids.child.lowercased): \(primary)"
    if let extra { childMsg += " \(extra)" }
    with(dependency: \.logger).info("\(childMsg)")
    var computerMsg = "[WS] compu=\(self.ids.computerUser.lowercased): \(primary)"
    if let extra { computerMsg += " \(extra)" }
    with(dependency: \.logger).info("\(computerMsg)")
  }

  func onPing() {
    self.lastActivity.withLock { $0 = Date() }
    self.log("received ping")
  }

  var isAlive: Bool {
    if self.ws.isClosed {
      return false
    }
    return self.lastActivity.withLock { lastActivity in
      let elapsed = Date().timeIntervalSince(lastActivity)
      return elapsed < 100 // 90 seconds is our macapp ping interval
    }
  }

  var isDead: Bool {
    !self.isAlive
  }

  func onText(_ json: String) {
    self.lastActivity.withLock { $0 = Date() }
    guard let message = try? JSON.decode(json, as: IncomingMessage.self) else {
      self.log("ERR failed to decode msg", extra: "json=\(json)")
      return
    }
    self.log("got message", extra: "\(message)")
    switch message {
    case .currentFilterState(let filterStateWithoutTimes):
      self.filterState.withLock { $0 = .withoutTimes(filterStateWithoutTimes) }
    case .currentFilterState_v2(let filterState):
      self.filterState.withLock { $0 = .withTimes(filterState) }
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
