import Foundation

extension UUID: UUIDStringable {}

#if DEBUG
  public extension UUID {
    nonisolated(unsafe) static var new: () -> UUID = UUID.init
  }
#endif

public protocol UUIDStringable: Sendable {
  var uuidString: String { get }
}

public protocol UUIDIdentifiable: Sendable {
  var uuidId: UUID { get }
}
