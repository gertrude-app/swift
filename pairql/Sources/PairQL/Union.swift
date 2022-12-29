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

public enum Union3<A: PairNestable, B: PairNestable, C: PairNestable>: PairNestable {
  case a(A)
  case b(B)
  case c(C)

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .a(let a):
      try Case(type: "\(type(of: a))", value: a).encode(to: encoder)
    case .b(let b):
      try Case(type: "\(type(of: b))", value: b).encode(to: encoder)
    case .c(let c):
      try Case(type: "\(type(of: c))", value: c).encode(to: encoder)
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let a = try? container.decode(Case<A>.self) {
      self = .a(a.value)
    } else if let b = try? container.decode(Case<B>.self) {
      self = .b(b.value)
    } else {
      let c = try container.decode(Case<C>.self)
      self = .c(c.value)
    }
  }
}

public extension Union3 {
  var a: A? {
    switch self {
    case .a(let a):
      return a
    case .b, .c:
      return nil
    }
  }

  var b: B? {
    switch self {
    case .b(let b):
      return b
    case .a, .c:
      return nil
    }
  }

  var c: C? {
    switch self {
    case .c(let c):
      return c
    case .a, .b:
      return nil
    }
  }
}
