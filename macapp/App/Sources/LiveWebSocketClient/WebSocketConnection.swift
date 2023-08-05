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
    state.withValue { $0 }
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
    logFn = log
    logErrorFn = logError
    socket = createSocket()
    connect(socket)
  }

  public func send(_ message: WebSocketMessage.FromAppToApi) {
    guard let json = try? JSON.encode(message) else {
      logError("failed to get json string from msg: \(message)")
      return
    }
    socket.write(string: json)
  }

  public func disconnect() {
    transition(receiving: .initiatingDisconnect)
    socket.disconnect()
  }

  public func clientState() -> ClientInterfaces.WebSocketClient.State {
    switch currentState {
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
      log("connection established")
      transition(receiving: .receivedConnected)

    case .disconnected(let reason, let code):
      log("disconnected, reason: \(reason), code: \(code)")
      transition(receiving: .receivedDisconnected(code: code))

    case .cancelled:
      log("connection cancelled")
      transition(receiving: .receivedCancelled)

    case .pong:
      log("received pong, connectivity confirmed")
      transition(receiving: .receivedPong)

    case .text(let json):
      guard let message = try? JSON.decode(json, as: WebSocketMessage.FromApiToApp.self) else {
        logError("failed to decode message: \(json)")
        return
      }
      messageSubject.withValue { [message] subject in
        subject.send(message)
      }

    default:
      log("other event received: \(event)")
    }
  }

  func connect(_ socket: Starscream.WebSocketClient) {
    self.socket = socket
    if let socket = socket as? WebSocket {
      socket.delegate = self
    }

    log("connecting")
    transition(receiving: .initiatingConnection)
    socket.connect()
    schedulePing()
  }

  func heartbeat() {
    guard currentState == .connected else {
      logError("websocket not connected in heartbeat")
      return
    }

    log("checking websocket connectivity in heartbeat")
    pingsSent += 1
    socket.write(ping: Data())
    transition(receiving: .sentPing)
    schedule(after: PONG_CONFIRMATION_DELAY) {
      [weak self] in self?.checkPongResponse()
    }
  }

  func checkPongResponse() {
    if currentState == .waitingForPong {
      logError("failed to receive timely pong")
      transition(receiving: .failedToReceiveTimelyPong)
    } else if currentState == .connected {
      schedulePing()
    } else {
      logError("unexpected state checking pong response")
    }
  }

  func schedulePing() {
    schedule(after: pingInterval) { [weak self] in self?.heartbeat() }
  }

  func schedule(after interval: IntervalInSeconds, action: @escaping () -> Void) {
    scheduler.schedule(after: scheduler.now.advanced(by: interval), action)
  }

  func transition(receiving event: ConnectionState.Event) {
    state.transition { [logFn] in $0.receive(event, log: logFn) }
  }

  func log(_ message: String) {
    logFn("\(message), state: `\(currentState)`")
  }

  func logError(_ message: String) {
    logErrorFn("\(message), state: `\(currentState)`")
  }
}

public typealias IntervalInSeconds = DispatchQueue.SchedulerTimeType.Stride
public let PONG_CONFIRMATION_DELAY: IntervalInSeconds = 5
