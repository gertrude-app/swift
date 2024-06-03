public struct AnyType {
  public var fullyQualifiedName: String
  public var name: String
  public var type: Any.Type
}

extension AnyType {
  init(_ Type: Any.Type) {
    self.init(
      fullyQualifiedName: String(reflecting: Type),
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

extension AnyType: Hashable {
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
