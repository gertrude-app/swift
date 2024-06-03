import ClientInterfaces
import Combine
import CombineSchedulers
import Core
import Foundation
import Gertie
import Starscream
import XCore

public class WebSocketConnection: WebSocketDelegate {
  public var createSocket: () -> Starscream.WebSocketClient
  public var logFn: @Sendable (String) -> Void
  public var logErrorFn: @Sendable (String) -> Void

  var socket: Starscream.WebSocketClient
  var scheduler: AnySchedulerOf<DispatchQueue>
  var messageSubject: Mutex<PassthroughSubject<WebSocketMessage.FromApiToApp, Never>>
  var pingInterval: IntervalInSeconds
  var pingsSent = 0
  var state = Mutex(ConnectionState.idle)

  var currentState: ConnectionState {
    self.state.withValue { $0 }
  }

  public init(
    scheduler: AnySchedulerOf<DispatchQueue> = .global(qos: .background),
    // use `300` literal instead of `60 * 5`, believe it or not, crashes in 10.15
    // https://github.com/OpenCombine/OpenCombine/issues/214#issuecomment-888958786
    pingInterval: IntervalInSeconds = 300, // five minutes
    log: @escaping @Sendable (String) -> Void = { _ in },
    logError: @escaping @Sendable (String) -> Void = { _ in },
    messageSubject: Mutex<PassthroughSubject<WebSocketMessage.FromApiToApp, Never>>,
    createSocket: @escaping () -> Starscream.WebSocketClient
  ) {
    self.scheduler = scheduler
    self.createSocket = createSocket
    self.pingInterval = pingInterval
    self.messageSubject = messageSubject
    self.logFn = log
    self.logErrorFn = logError
    self.socket = createSocket()
    self.connect(self.socket)
  }

  public func send(_ message: WebSocketMessage.FromAppToApi) {
    guard let json = try? JSON.encode(message) else {
      self.logError("failed to get json string from msg: \(message)")
      return
    }
    self.socket.write(string: json)
  }

  public func disconnect() {
    self.transition(receiving: .initiatingDisconnect)
    self.socket.disconnect()
  }

  public func clientState() -> ClientInterfaces.WebSocketClient.State {
    switch self.currentState {
    case .connected:
      return .connected
    case .disconnected:
      return .notConnected
    case .idle:
      return .notConnected
    case .connecting:
      return .connecting
    case .waitingForPong:
      return .connected
    }
  }

  public func didReceive(event: WebSocketEvent, client: WebSocket) {
    switch event {

    case .connected:
      self.log("connection established")
      self.transition(receiving: .receivedConnected)

    case .disconnected(let reason, let code):
      self.log("disconnected, reason: \(reason), code: \(code)")
      self.transition(receiving: .receivedDisconnected(code: code))

    case .cancelled:
      self.log("connection cancelled")
      self.transition(receiving: .receivedCancelled)

    case .pong:
      self.log("received pong, connectivity confirmed")
      self.transition(receiving: .receivedPong)

    case .text(let json):
      guard let message = try? JSON.decode(json, as: WebSocketMessage.FromApiToApp.self) else {
        self.logError("failed to decode message: \(json)")
        return
      }
      self.messageSubject.withValue { [message] subject in
        subject.send(message)
      }

    default:
      self.log("other event received: \(event)")
    }
  }

  func connect(_ socket: Starscream.WebSocketClient) {
    self.socket = socket
    if let socket = socket as? WebSocket {
      socket.delegate = self
    }

    self.log("connecting")
    self.transition(receiving: .initiatingConnection)
    socket.connect()
    self.schedulePing()
  }

  func heartbeat() {
    guard self.currentState == .connected else {
      self.logError("websocket not connected in heartbeat")
      return
    }

    self.log("checking websocket connectivity in heartbeat")
    self.pingsSent += 1
    self.socket.write(ping: Data())
    self.transition(receiving: .sentPing)
    self.schedule(after: PONG_CONFIRMATION_DELAY) {
      [weak self] in self?.checkPongResponse()
    }
  }

  func checkPongResponse() {
    if self.currentState == .waitingForPong {
      self.logError("failed to receive timely pong")
      self.transition(receiving: .failedToReceiveTimelyPong)
    } else if self.currentState == .connected {
      self.schedulePing()
    } else {
      self.logError("unexpected state checking pong response")
    }
  }

  func schedulePing() {
    self.schedule(after: self.pingInterval) { [weak self] in self?.heartbeat() }
  }

  func schedule(after interval: IntervalInSeconds, action: @escaping () -> Void) {
    self.scheduler.schedule(after: self.scheduler.now.advanced(by: interval), action)
  }

  func transition(receiving event: ConnectionState.Event) {
    self.state.transition { [logFn] in $0.receive(event, log: logFn) }
  }

  func log(_ message: String) {
    self.logFn("\(message), state: `\(self.currentState)`")
  }

  func logError(_ message: String) {
    self.logErrorFn("\(message), state: `\(self.currentState)`")
  }
}

public typealias IntervalInSeconds = DispatchQueue.SchedulerTimeType.Stride
public let PONG_CONFIRMATION_DELAY: IntervalInSeconds = 5
