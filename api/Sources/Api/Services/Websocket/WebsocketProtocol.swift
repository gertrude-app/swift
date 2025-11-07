import Gertie
import NIOWebSocket
import Vapor
import XCore

protocol WebsocketProtocol {
  func onText(_ callback: @Sendable @escaping (Self, String) async -> Void)
  func close(code: WebSocketErrorCode) async throws
  func close(code: WebSocketErrorCode) -> EventLoopFuture<Void>
  var onClose: EventLoopFuture<Void> { get }
  var isClosed: Bool { get }
  func send(_ text: some Collection<Character>) async throws
}

extension WebSocket: WebsocketProtocol {}

extension WebsocketProtocol {
  func send(codable msg: some Codable) async throws {
    try await self.send(JSON.encode(msg))
  }

  func send(app: WebSocketMessage.FromApiToApp) async throws {
    try await self.send(codable: app)
  }
}
