import Foundation

public actor Connection {
  private var connection: NSXPCConnection

  public init(_ create: @Sendable () -> NSXPCConnection) {
    connection = create()
  }

  public init(taking value: Move<NSXPCConnection>) {
    connection = value.consume()
  }

  public func withUnderlying(
    operation: @Sendable (NSXPCConnection) async throws -> Void
  ) async throws {
    try await operation(connection)
  }

  public func replace(with create: @Sendable () -> NSXPCConnection) {
    connection = create()
  }
}
