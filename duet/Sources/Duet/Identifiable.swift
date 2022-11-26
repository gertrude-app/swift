import Foundation

public protocol Identifiable: UUIDIdentifiable {
  associatedtype IdValue: RandomEmptyInitializing, UUIDStringable, Hashable
  var id: IdValue { get set }
}

public extension Identifiable where IdValue: RawRepresentable, IdValue.RawValue == UUID {
  var uuidId: UUID { id.rawValue }
}

public protocol RandomEmptyInitializing {
  init()
}

public func == (lhs: UUIDStringable, rhs: UUID) -> Bool {
  lhs.uuidString == rhs.uuidString
}

public func == (lhs: UUID, rhs: UUIDStringable) -> Bool {
  lhs.uuidString == rhs.uuidString
}
