public protocol Mock {
  static var mock: Self { get }
  static var empty: Self { get }
  static var random: Self { get }
}

public extension Mock {
  static func mock(with config: (inout Self) -> Void) -> Self {
    var admin = Self.random
    config(&admin)
    return admin
  }

  static func empty(with config: (inout Self) -> Void) -> Self {
    var admin = Self.random
    config(&admin)
    return admin
  }

  static func random(with config: (inout Self) -> Void) -> Self {
    var admin = Self.random
    config(&admin)
    return admin
  }
}
