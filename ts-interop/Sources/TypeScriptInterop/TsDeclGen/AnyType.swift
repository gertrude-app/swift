public struct AnyType {
  public var fullyQualifiedName: String
  public var name: String
  public var type: Any.Type
}

extension AnyType {
  init(_ Type: Any.Type) {
    self.init(
      // `Swift._typeName(_:qualified:)` is called out to by String(reflecting:),
      // but after it creates a Mirror, which is never used, because we only ever
      // call it with a meta-type. avoiding creating the mirror gives a
      // major performance boost, and we were relying on the private func anyway
      fullyQualifiedName: Swift._typeName(Type.self, qualified: true),
      name: "\(Type)",
      type: Type
    )
  }
}

extension AnyType: Equatable {
  public static func == (lhs: AnyType, rhs: AnyType) -> Bool {
    lhs.fullyQualifiedName == rhs.fullyQualifiedName && lhs.name == rhs.name
  }
}

extension AnyType: Hashable, Sendable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.fullyQualifiedName)
    hasher.combine(self.name)
  }
}

extension AnyType {
  static let string = AnyType(String.self)
  static let int = AnyType(Int.self)
  static let bool = AnyType(Bool.self)

  static func array<T>(of type: T) -> AnyType {
    AnyType([T].self)
  }
}
