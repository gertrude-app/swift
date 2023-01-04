private struct Case<T: PairNestable>: PairNestable {
  var type: String
  var value: T
}

public enum Union2<
  T1: PairNestable,
  T2: PairNestable
>: PairNestable, PairInput, PairOutput {
  case t1(T1)
  case t2(T2)

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .t1(let t1):
      try Case(type: "\(type(of: t1))", value: t1).encode(to: encoder)
    case .t2(let t2):
      try Case(type: "\(type(of: t2))", value: t2).encode(to: encoder)
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let t1 = try? container.decode(Case<T1>.self) {
      self = .t1(t1.value)
    } else {
      let t2 = try container.decode(Case<T2>.self)
      self = .t2(t2.value)
    }
  }
}

public extension Union2 {
  var t1: T1? {
    switch self {
    case .t1(let t1):
      return t1
    case .t2:
      return nil
    }
  }

  var t2: T2? {
    switch self {
    case .t1:
      return nil
    case .t2(let t2):
      return t2
    }
  }
}

public enum Union3<
  T1: PairNestable,
  T2: PairNestable,
  T3: PairNestable
>: PairNestable, PairInput, PairOutput {
  case t1(T1)
  case t2(T2)
  case t3(T3)

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .t1(let t1):
      try Case(type: "\(type(of: t1))", value: t1).encode(to: encoder)
    case .t2(let t2):
      try Case(type: "\(type(of: t2))", value: t2).encode(to: encoder)
    case .t3(let t3):
      try Case(type: "\(type(of: t3))", value: t3).encode(to: encoder)
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let t1 = try? container.decode(Case<T1>.self) {
      self = .t1(t1.value)
    } else if let t2 = try? container.decode(Case<T2>.self) {
      self = .t2(t2.value)
    } else {
      let t3 = try container.decode(Case<T3>.self)
      self = .t3(t3.value)
    }
  }
}
