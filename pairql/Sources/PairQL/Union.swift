private struct Case<T: PairNestable>: PairNestable {
  var type: String
  var value: T
}

public enum Union2<A: PairNestable, B: PairNestable>: PairNestable {
  case a(A)
  case b(B)

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .a(let a):
      try Case(type: "\(type(of: a))", value: a).encode(to: encoder)
    case .b(let b):
      try Case(type: "\(type(of: b))", value: b).encode(to: encoder)
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let a = try? container.decode(Case<A>.self) {
      self = .a(a.value)
    } else {
      let b = try container.decode(Case<B>.self)
      self = .b(b.value)
    }
  }
}

public extension Union2 {
  var a: A? {
    switch self {
    case .a(let a):
      return a
    case .b:
      return nil
    }
  }

  var b: B? {
    switch self {
    case .a:
      return nil
    case .b(let b):
      return b
    }
  }
}
