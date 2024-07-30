import NIOWebSocket
import Vapor
import XCore

protocol WebsocketProtocol {
  func onText(_ callback: @Sendable @escaping (Self, String) async -> Void)
  func close(code: WebSocketErrorCode) async throws
  func close(code: WebSocketErrorCode) -> EventLoopFuture<Void>
  var onClose: EventLoopFuture<Void> { get }
  var isClosed: Bool { get }
  func send<S>(_ text: S) async throws
    where S: Collection, S.Element == Character
}

extension WebSocket: WebsocketProtocol {}

extension WebsocketProtocol {
  func send<T: Codable>(codable msg: T) async throws {
    try await self.send(try JSON.encode(msg))
  }
}
