// @see https://github.com/apple/swift/blob/main/stdlib/public/core/EitherSequence.swift

enum Either<Left, Right> {
  case left(Left)
  case right(Right)
}

extension Either {
  func mapLeft<NewLeft>(
    _ transform: (Left) -> NewLeft
  ) -> Either<NewLeft, Right> {
    switch self {
    case .left(let left):
      .left(transform(left))
    case .right(let right):
      .right(right)
    }
  }

  func mapRight<NewRight>(
    _ transform: (Right) -> NewRight
  ) -> Either<Left, NewRight> {
    switch self {
    case .left(let left):
      .left(left)
    case .right(let right):
      .right(transform(right))
    }
  }
}

extension Either {
  func `is`(_: Left.Type) -> Bool {
    switch self {
    case .left:
      true
    case .right:
      false
    }
  }

  func `is`(_: Right.Type) -> Bool {
    switch self {
    case .left:
      false
    case .right:
      true
    }
  }
}

extension Either {
  var left: Left? {
    get {
      guard case .left(let left) = self else {
        return nil
      }
      return left
    }
    set {
      if let newValue {
        self = .left(newValue)
      }
    }
  }

  var right: Right? {
    get {
      guard case .right(let right) = self else {
        return nil
      }
      return right
    }
    set {
      if let newValue {
        self = .right(newValue)
      }
    }
  }
}

extension Either {
  init(_ left: Left, or other: Right.Type) { self = .left(left) }
  init(_ left: Left) { self = .left(left) }
  init(_ right: Right) { self = .right(right) }
}

extension Either: Equatable where Left: Equatable, Right: Equatable {
  static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.left(let l), .left(let r)): l == r
    case (.right(let l), .right(let r)): l == r
    case (.left, .right), (.right, .left): false
    }
  }
}

extension Either: Comparable where Left: Comparable, Right: Comparable {
  static func < (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.left(let l), .left(let r)): l < r
    case (.right(let l), .right(let r)): l < r
    case (.left, .right): true
    case (.right, .left): false
    }
  }
}
