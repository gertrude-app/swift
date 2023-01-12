import Combine
import CombineSchedulers
import Foundation
import Shared
import Starscream
import XCore

public typealias IncomingMessage = Shared.WebsocketMsg.ApiToApp.Message
public typealias OutgoingMessage = Shared.WebsocketMsg.AppToApi.Message

public class WebsocketConnection: WebSocketDelegate {
  public var createSocket: () -> WebSocketClient
  public var handleIncomingMessage: (String) -> Void
  public var log: (String) -> Void
  public var logError: (String) -> Void
  public var shouldRepairConnection = true

  var socket: WebSocketClient
  var scheduler: AnySchedulerOf<DispatchQueue>
  var heartbeatInterval: Interval
  var heartbeats = 0
  var state = ConnectionState()

  public init(
    scheduler: AnySchedulerOf<DispatchQueue> = .main,
    heartbeatInterval: Interval = FIVE_MINUTES,
    log: @escaping (String) -> Void = { _ in },
    logError: @escaping (String) -> Void = { _ in },
    handleIncomingMessage: @escaping (String) -> Void = { _ in },
    createSocket: @escaping () -> WebSocketClient
  ) {
    self.scheduler = scheduler
    self.createSocket = createSocket
    self.heartbeatInterval = heartbeatInterval
    self.log = log
    self.logError = logError
    self.handleIncomingMessage = handleIncomingMessage
    socket = createSocket()
    connect(socket)
  }

  public func send<T: Codable>(_ message: T) {
    guard let json = try? JSON.encode(message) else {
      logError("failed to get json string from msg: \(message)")
      return
    }
    socket.write(string: json)
  }

  public func disconnect() {
    state.handle(.initiatingDisconnect)
    socket.disconnect()
  }

  public func reconnect() {
    disconnect()
    schedule(after: 5) { [weak self] in
      guard let self = self else { return }
      self.connect(self.createSocket())
    }
  }

  func connect(_ socket: WebSocketClient) {
    self.socket = socket
    if let socket = socket as? WebSocket {
      socket.delegate = self
    }

    state.handle(.initiatingConnection)
    socket.connect()
    scheduleNextHeartbeat()
  }

  func heartbeat() {
    guard state.get == .connected else {
      logError("websocket not connected in heartbeat")
      return
    }

    log("checking websocket connectivity in heartbeat")
    heartbeats += 1
    socket.write(ping: Data())
    state.handle(.sentPing)
    schedule(after: 5) { [weak self] in self?.checkPongResponse() }
  }

  func checkPongResponse() {
    if state.get == .waitingForPong {
      logError("failed to receive timely pong, attempting reconnect")
      state.handle(.failedToReceiveTimelyPong)
      connect(createSocket())
    } else {
      scheduleNextHeartbeat()
    }
  }

  func scheduleNextHeartbeat() {
    schedule(after: heartbeatInterval) { [weak self] in self?.heartbeat() }
  }

  func schedule(after interval: Interval, action: @escaping () -> Void) {
    scheduler.schedule(after: scheduler.now.advanced(by: interval), action)
  }

  public func didReceive(event: WebSocketEvent, client: WebSocket) {
    switch event {

    case .connected:
      log("connection established")
      state.handle(.receivedConnected)

    case .disconnected(let reason, let code):
      log("disconnected, reason: \(reason), code: \(code)")
      state.handle(.receivedDisconnected(code: code))
      let delay = code == WebsocketMsg.Error.USER_TOKEN_NOT_FOUND ? ONE_HOUR : THREE_MINUTES
      schedule(after: delay) { [weak self] in
        guard let self = self, self.shouldRepairConnection else { return }
        self.connect(self.createSocket())
      }

    case .cancelled:
      log("connection cancelled")
      state.handle(.receivedCancelled)
      schedule(after: 30) { [weak self] in
        guard let self = self, self.shouldRepairConnection else { return }
        self.connect(self.createSocket())
      }

    case .pong:
      log("received pong, connectivity confirmed")
      state.handle(.receivedPong)

    case .text(let json):
      handleIncomingMessage(json)

    default:
      log("other event received: \(event)")
    }
  }
}

public typealias Interval = DispatchQueue.SchedulerTimeType.Stride
public let PONG_CONFIRMATION_DELAY: Interval = 5
public let THREE_MINUTES: Interval = 60 * 3
public let FIVE_MINUTES: Interval = 60 * 5
public let ONE_HOUR: Interval = 60 * 60
