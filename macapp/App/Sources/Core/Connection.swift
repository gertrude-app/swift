import Foundation

public actor Connection {
  private var connection: NSXPCConnection

  public init(_ create: @Sendable () -> NSXPCConnection) {
    self.connection = create()
  }

  public init(taking value: Move<NSXPCConnection>) {
    self.connection = value.consume()
  }

  public func withUnderlying(
    operation: @Sendable (NSXPCConnection) async throws -> Void
  ) async throws {
    try await operation(self.connection)
  }

  public func replace(with create: @Sendable () -> NSXPCConnection) {
    self.connection = create()
  }

  deinit {
    connection.invalidate()
  }
}
