import Runtime

public protocol MemoryStore {
  typealias Models<M: Model> = ReferenceWritableKeyPath<Self, [M.IdValue: M]>
  func keyPath<M: Model>(to: M.Type) -> Models<M>
}

public extension MemoryStore {
  func models<M: Model>(of: M.Type) throws -> [M.IdValue: M] {
    self[keyPath: keyPath(to: M.self)]
  }

  func flush() {
    // no-op customization point
  }
}

public struct MemoryClient<Store: MemoryStore>: Client {
  public actor ThreadSafe<Store: MemoryStore> {
    public var store: Store

    public func flush() {
      store.flush()
    }

    @discardableResult
    public func set<M: Model>(_ model: M) -> M {
      let keyPath = store.keyPath(to: M.self)
      store[keyPath: keyPath][model.id] = model
      return model
    }

    @discardableResult
    public func set<M: Model>(_ models: [M]) -> [M] {
      let keyPath = store.keyPath(to: M.self)
      for model in models {
        store[keyPath: keyPath][model.id] = model
      }
      return models
    }

    @discardableResult
    public func delete<M: Model>(_ model: M) -> M {
      let keyPath = store.keyPath(to: M.self)
      store[keyPath: keyPath][model.id] = nil
      return model
    }

    @discardableResult
    public func delete<M: Model>(_ models: [M]) -> [M] {
      let keyPath = store.keyPath(to: M.self)
      for model in models {
        store[keyPath: keyPath][model.id] = nil
      }
      return models
    }

    func models<M: Model>(of: M.Type) throws -> [M.IdValue: M] {
      store[keyPath: store.keyPath(to: M.self)]
    }

    public init(store: Store) {
      self.store = store
    }
  }

  private var store: ThreadSafe<Store>

  public init(store: Store) {
    self.store = ThreadSafe(store: store)
  }

  public func flush() async {
    await store.flush()
  }

  public func select<M: Model>(
    _ Model: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
    orderBy: SQL.Order<M>? = nil,
    limit: Int? = nil,
    offset: Int? = nil,
    withSoftDeleted: Bool = false
  ) async throws -> [M] {
    var models = Array(try await store.models(of: Model).values)
    models = models.filter {
      $0.satisfies(constraint: constraint + (withSoftDeleted ? .always : .notSoftDeleted))
    }
    if let orderBy = orderBy {
      try models.order(by: orderBy)
    }

    if let limit = limit {
      let start = offset ?? 0
      models = Array(models[start ... min(start + limit - 1, models.count - 1)])
    } else if let offset = offset, offset > 0 {
      models = Array(models[(offset - 1)...])
    }
    return models
  }

  public func create<M: Model>(_ insert: [M]) async throws -> [M] {
    for model in insert {
      await store.set(model)
    }
    return insert
  }

  public func update<M: Model>(_ model: M) async throws -> M {
    return await store.set(model)
  }

  public func forceDelete<M: Model>(
    _ Model: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
    orderBy: SQL.Order<M>? = nil,
    limit: Int? = nil,
    offset: Int? = nil
  ) async throws -> [M] {
    let selected = try await select(
      Model,
      where: constraint,
      orderBy: orderBy,
      limit: limit,
      withSoftDeleted: true
    )
    return await store.delete(selected)
  }

  public func delete<M: Model>(
    _ Model: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
    orderBy: SQL.Order<M>? = nil,
    limit: Int? = nil,
    offset: Int? = nil
  ) async throws -> [M] {
    let selected = try await select(Model, where: constraint, orderBy: orderBy, limit: limit)
    if (try? M.column("deleted_at")) != nil,
       let info = try? typeInfo(of: M.self),
       let deletedAt = try? info.property(named: "deletedAt") {
      for var model in selected {
        try? deletedAt.set(value: Date(), on: &model)
      }
      return selected
    }
    return await store.delete(selected)
  }

  public func queryJoined<J: SQLJoined>(
    _ Joined: J.Type,
    withBindings bindings: [Postgres.Data]? = nil
  ) async throws -> [J] {
    try await J.memoryQuery(bindings: bindings)
  }

  public func count<M: Model>(
    _: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
    withSoftDeleted: Bool = false
  ) async throws -> Int {
    try await select(M.self, where: constraint, withSoftDeleted: withSoftDeleted).count
  }
}
