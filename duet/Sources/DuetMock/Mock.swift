public protocol Mock {
  static var mock: Self { get }
  static var empty: Self { get }
  static var random: Self { get }
}

public extension Mock {
  static func mock(with config: (inout Self) -> Void) -> Self {
    var model = Self.random
    config(&model)
    return model
  }

  static func empty(with config: (inout Self) -> Void) -> Self {
    var model = Self.random
    config(&model)
    return model
  }

  static func random(with config: (inout Self) -> Void) -> Self {
    var model = Self.random
    config(&model)
    return model
  }
}
