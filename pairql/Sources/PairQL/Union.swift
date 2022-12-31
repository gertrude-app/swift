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

public extension Union3 {
  var t1: T1? {
    switch self {
    case .t1(let t1):
      return t1
    case .t2, .t3:
      return nil
    }
  }

  var t2: T2? {
    switch self {
    case .t1, .t3:
      return nil
    case .t2(let t2):
      return t2
    }
  }

  var t3: T3? {
    switch self {
    case .t1, .t2:
      return nil
    case .t3(let t3):
      return t3
    }
  }
}

public enum Union6<
  T1: PairNestable,
  T2: PairNestable,
  T3: PairNestable,
  T4: PairNestable,
  T5: PairNestable,
  T6: PairNestable
>: PairNestable, PairInput, PairOutput {
  case t1(T1)
  case t2(T2)
  case t3(T3)
  case t4(T4)
  case t5(T5)
  case t6(T6)

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .t1(let t1):
      try Case(type: "\(type(of: t1))", value: t1).encode(to: encoder)
    case .t2(let t2):
      try Case(type: "\(type(of: t2))", value: t2).encode(to: encoder)
    case .t3(let t3):
      try Case(type: "\(type(of: t3))", value: t3).encode(to: encoder)
    case .t4(let t4):
      try Case(type: "\(type(of: t4))", value: t4).encode(to: encoder)
    case .t5(let t5):
      try Case(type: "\(type(of: t5))", value: t5).encode(to: encoder)
    case .t6(let t6):
      try Case(type: "\(type(of: t6))", value: t6).encode(to: encoder)
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let t1 = try? container.decode(Case<T1>.self) {
      self = .t1(t1.value)
    } else if let t2 = try? container.decode(Case<T2>.self) {
      self = .t2(t2.value)
    } else if let t3 = try? container.decode(Case<T3>.self) {
      self = .t3(t3.value)
    } else if let t4 = try? container.decode(Case<T4>.self) {
      self = .t4(t4.value)
    } else if let t5 = try? container.decode(Case<T5>.self) {
      self = .t5(t5.value)
    } else {
      let t6 = try container.decode(Case<T6>.self)
      self = .t6(t6.value)
    }
  }
}

public extension Union6 {
  var t1: T1? {
    switch self {
    case .t1(let t1):
      return t1
    case .t2, .t3, .t4, .t5, .t6:
      return nil
    }
  }

  var t2: T2? {
    switch self {
    case .t1, .t3, .t4, .t5, .t6:
      return nil
    case .t2(let t2):
      return t2
    }
  }

  var t3: T3? {
    switch self {
    case .t1, .t2, .t4, .t5, .t6:
      return nil
    case .t3(let t3):
      return t3
    }
  }

  var t4: T4? {
    switch self {
    case .t1, .t2, .t3, .t5, .t6:
      return nil
    case .t4(let t4):
      return t4
    }
  }

  var t5: T5? {
    switch self {
    case .t1, .t2, .t3, .t4, .t6:
      return nil
    case .t5(let t5):
      return t5
    }
  }

  var t6: T6? {
    switch self {
    case .t1, .t2, .t3, .t4, .t5:
      return nil
    case .t6(let t6):
      return t6
    }
  }
}
