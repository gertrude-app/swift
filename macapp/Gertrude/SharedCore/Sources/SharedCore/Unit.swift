public struct Unit {
  private init() {}
  public static let value = Unit()
  public static var unit: Self { value }
}

extension Unit: Equatable {
  public static func == (lhs: Unit, rhs: Unit) -> Bool {
    true
  }
}

public extension Result where Success == Unit {
  static var success: Self {
    .success(.unit)
  }
}

public extension Result where Failure == Unit {
  static var failure: Self {
    .failure(.unit)
  }
}

extension Unit: Error {}
extension Unit: Hashable {}
