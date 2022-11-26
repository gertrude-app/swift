import Foundation

extension UUID: UUIDStringable {}

public extension UUID {
  static var new: () -> UUID = UUID.init
}

public protocol UUIDStringable {
  var uuidString: String { get }
}

public protocol UUIDIdentifiable {
  var uuidId: UUID { get }
}
