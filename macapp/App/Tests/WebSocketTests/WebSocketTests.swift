import Combine
import CombineSchedulers
import Core
import Gertie
import Starscream
import XCore
import XCTest
import XExpect

@testable import LiveWebSocketClient

final class WebsocketTests: XCTestCase {
  var scheduler = DispatchQueue.test
  var socket = TestSocket()
  var conn: LiveWebSocketClient.WebSocketConnection!
  var receivedMessages: [WebSocketMessage.FromApiToApp] = []
  var cancellables: Set<AnyCancellable> = []

  var state: LiveWebSocketClient.ConnectionState { self.conn.currentState }
  var ws: WebSocket { WebSocket(request: .init(url: URL(string: "/")!)) }

  override func setUp() {
    self.receivedMessages = []

    let subject = PassthroughSubject<WebSocketMessage.FromApiToApp, Never>()
    subject.eraseToAnyPublisher().sink { [self] in
      self.receivedMessages.append($0)
    }.store(in: &self.cancellables)

    self.scheduler = DispatchQueue.test
    self.conn = WebSocketConnection(
      scheduler: self.scheduler.eraseToAnyScheduler(),
      messageSubject: Mutex(subject)
    ) { [self] in
      self.socket = TestSocket()
      return self.socket
    }
  }

  func send(_ event: WebSocketEvent) {
    self.conn.didReceive(event: event, client: self.ws)
  }

  func testConnection() throws {
    expect(self.state).toEqual(.idle)
    expect(self.socket.connectCalls).toEqual(1)

    self.send(.connected([:]))
    expect(self.state).toEqual(.connected)

    self.send(.disconnected("some reason", 1))
    expect(self.state).toEqual(.disconnected)
  }

  func testDisconnect() {
    self.send(.connected([:]))
    expect(self.state).toEqual(.connected)

    self.send(.disconnected("some reason", 1))
    expect(self.state).toEqual(.disconnected)

    // never tries to reconnect on its own (app heartbeat responsible)
    self.scheduler.advance(by: 1000)
    expect(self.state).toEqual(.disconnected)
  }

  func testPingPong() {
    self.send(.connected([:]))

    self.scheduler.advance(by: self.conn.pingInterval - 1)
    expect(self.state).toEqual(.connected)

    self.scheduler.advance(by: 1)
    expect(self.state).toEqual(.waitingForPong)

    self.send(.pong(nil))
    expect(self.state).toEqual(.connected)

    self.scheduler.advance(by: PONG_CONFIRMATION_DELAY + self.conn.pingInterval - 1)
    expect(self.state).toEqual(.connected)

    self.scheduler.advance(by: 1)
    expect(self.state).toEqual(.waitingForPong)

    self.send(.pong(nil))
    expect(self.state).toEqual(.connected)
  }

  func testFailedToReceivePongReestablishesConnection() {
    self.send(.connected([:]))

    self.scheduler.advance(by: self.conn.pingInterval - 1)
    expect(self.conn.pingsSent).toEqual(0)
    expect(self.state).toEqual(.connected)

    self.scheduler.advance(by: 1)
    expect(self.state).toEqual(.waitingForPong)
    expect(self.conn.pingsSent).toEqual(1)

    self.scheduler.advance(by: 5) // should have receive pong by now!
    expect(self.state).toEqual(.disconnected)
  }

  // test that it passes messages on
  func testPassesMessagesOnToHandler() throws {
    self.send(.connected([:]))

    let message = WebSocketMessage.FromApiToApp.currentFilterStateRequested
    let json = try JSON.encode(message)
    self.send(.text(json))

    expect(self.receivedMessages).toEqual([.currentFilterStateRequested])
  }

  func testReceivingCancelledReschedulesConnectionIn30Seconds() {
    self.send(.connected([:]))

    self.send(.cancelled)
    expect(self.state).toEqual(.disconnected)

    // never tries to reconnect on its own (app heartbeat responsible)
    self.scheduler.advance(by: 1000)
    expect(self.state).toEqual(.disconnected)
  }

  func testDirectDisconnect() {
    self.send(.connected([:]))
    expect(self.state).toEqual(.connected)

    self.conn.disconnect()
    expect(self.state).toEqual(.disconnected)
    expect(self.socket.disconnectCalls).toEqual(1)
  }
}

// helpers

class TestSocket: WebSocketClient {
  var connectCalls = 0
  var disconnectCalls = 0

  func connect() {
    self.connectCalls += 1
  }

  func disconnect(closeCode: UInt16) {
    self.disconnectCalls += 1
  }

  func write(string: String, completion: (() -> Void)?) {}
  func write(stringData: Data, completion: (() -> Void)?) {}
  func write(data: Data, completion: (() -> Void)?) {}
  func write(ping: Data, completion: (() -> Void)?) {}
  func write(pong: Data, completion: (() -> Void)?) {}
}
