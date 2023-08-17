#if DEBUG
  public protocol Mocked {
    static var mock: Self { get }
    static var empty: Self { get }
  }

  public protocol RandomMocked: Mocked {
    static var random: Self { get }
  }

  public extension Mocked {
    static func mock(with config: (inout Self) -> Void) -> Self {
      var model = Self.mock
      config(&model)
      return model
    }

    static func empty(with config: (inout Self) -> Void) -> Self {
      var model = Self.empty
      config(&model)
      return model
    }
  }

  public extension RandomMocked {
    static func random(with config: (inout Self) -> Void) -> Self {
      var model = Self.random
      config(&model)
      return model
    }
  }

  extension Int: RandomMocked {
    public static var mock: Int { 42 }
    public static var empty: Int { 0 }
    public static var random: Int { Int.random(in: 0 ... Int.max) }
  }

  extension Int64: RandomMocked {
    public static var mock: Int64 { 42 }
    public static var empty: Int64 { 0 }
    public static var random: Int64 { Int64.random(in: 1_000_000_000 ... 9_999_999_999) }
  }

  extension String: RandomMocked {
    public static var mock: String { "mocked-string" }
    public static var empty: String { "" }
    public static var random: String { "random-string".random }
    public var random: String { "\(self) \(Int.random)" }
  }
#endif
