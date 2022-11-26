public enum RelationError: Error {
  case notLoaded
}

public enum Siblings<C: Duet.Identifiable> {
  case notLoaded
  case loaded([C])

  public var isLoaded: Bool {
    guard case .loaded = self else { return false }
    return true
  }

  public var models: [C] {
    get throws {
      guard case .loaded(let loaded) = self else {
        throw RelationError.notLoaded
      }
      return loaded
    }
  }
}

public enum Children<C: Duet.Identifiable> {
  case notLoaded
  case loaded([C])

  public var isLoaded: Bool {
    guard case .loaded = self else { return false }
    return true
  }

  public var models: [C] {
    get throws {
      guard case .loaded(let loaded) = self else {
        throw RelationError.notLoaded
      }
      return loaded
    }
  }
}

public enum Parent<P: Duet.Identifiable> {
  case notLoaded
  case loaded(P)

  public var isLoaded: Bool {
    guard case .loaded = self else { return false }
    return true
  }

  public var model: P {
    get throws {
      guard case .loaded(let loaded) = self else {
        throw RelationError.notLoaded
      }
      return loaded
    }
  }
}

public enum OptionalParent<P: Duet.Identifiable> {
  case notLoaded
  case loaded(P?)

  public var isLoaded: Bool {
    guard case .loaded = self else { return false }
    return true
  }

  public var model: P? {
    get throws {
      guard case .loaded(let loaded) = self else {
        throw RelationError.notLoaded
      }
      return loaded
    }
  }
}

public enum OptionalChild<C: Duet.Identifiable> {
  case notLoaded
  case loaded(C?)

  public var isLoaded: Bool {
    guard case .loaded = self else { return false }
    return true
  }

  public var model: C? {
    get throws {
      guard case .loaded(let loaded) = self else {
        throw RelationError.notLoaded
      }
      return loaded
    }
  }
}

public func connect<P: Duet.Identifiable, C: Duet.Identifiable>(
  _ parent: P,
  _ toChildren: ReferenceWritableKeyPath<P, Children<C>>,
  to children: [C],
  _ toParent: ReferenceWritableKeyPath<C, Parent<P>>
) {
  parent[keyPath: toChildren] = .loaded(children)
  children.forEach { $0[keyPath: toParent] = .loaded(parent) }
}

public func connect<P: Duet.Identifiable, C: Duet.Identifiable>(
  _ parent: P,
  _ toChildren: ReferenceWritableKeyPath<P, OptionalChild<C>>,
  to child: C?,
  _ toParent: ReferenceWritableKeyPath<C, Parent<P>>
) {
  parent[keyPath: toChildren] = .loaded(child)
  child?[keyPath: toParent] = .loaded(parent)
}

public func connect<P: Duet.Identifiable, C: Duet.Identifiable>(
  _ parent: P,
  _ toChildren: ReferenceWritableKeyPath<P, OptionalChild<C>>,
  to child: C?,
  _ toParent: ReferenceWritableKeyPath<C, OptionalParent<P>>
) {
  parent[keyPath: toChildren] = .loaded(child)
  child?[keyPath: toParent] = .loaded(parent)
}
