import Duet

import PostgresKit

public protocol Client: Sendable {
  @discardableResult
  func execute(raw: SQLQueryString) async throws -> [SQLRow]

  @discardableResult
  func execute(statement: SQL.Statement) async throws -> [SQLRow]

  func execute<M: Model>(statement: SQL.Statement, returning: M.Type) async throws -> [M]
}

public extension Client {
  func query<M: Model>(_ Model: M.Type) -> DuetQuery<M> {
    DuetQuery<M>()
  }

  func find<M: Model>(_ id: Tagged<M, UUID>, withSoftDeleted: Bool = false) async throws -> M {
    try await self.find(M.self, byId: id.rawValue, withSoftDeleted: withSoftDeleted)
  }

  func find<M: Model>(_: M.Type, byId id: UUID, withSoftDeleted: Bool = false) async throws -> M {
    let models = try await self.select(
      M.self,
      where: .equals(M.ColumnName.id, .uuid(id)),
      withSoftDeleted: withSoftDeleted,
    )
    guard let model = models.first else {
      throw DuetSQLError.notFound("\(M.self)")
    }
    return model
  }

  func find<M: Model>(
    _: M.Type,
    byId id: M.IdValue,
    withSoftDeleted: Bool = false,
  ) async throws -> M {
    let models = try await self.select(
      M.self,
      where: .equals(M.ColumnName.id, .uuid(id)),
      withSoftDeleted: withSoftDeleted,
    )
    guard let model = models.first else {
      throw DuetSQLError.notFound("\(M.self)")
    }
    return model
  }

  @discardableResult
  func upsert<M: Model>(_ model: M) async throws -> M {
    if await (try? self.find(M.self, byId: model.id)) == nil {
      try await self.create(model)
    } else {
      try await self.update(model)
    }
  }

  @discardableResult
  func create<M: Model>(_ models: [M]) async throws -> [M] {
    guard !models.isEmpty else { return [] }
    let stmt = SQL.Statement.create(models)
    try await self.execute(statement: stmt)
    return models
  }

  @discardableResult
  func create<M: Model>(_ model: M) async throws -> M {
    let models = try await self.create([model])
    return models.first ?? model
  }

  @discardableResult
  func update<M: Model>(_ model: M) async throws -> M {
    let stmt = SQL.Statement.update(model)
    let models = try await self.execute(statement: stmt, returning: M.self)
    #if !DEBUG
      return model
    #else
      precondition(models.count == 1)
      return models[0]
    #endif
  }

  @discardableResult
  func update<M: Model>(_ models: [M]) async throws -> [M] {
    guard !models.isEmpty else { return [] }
    return try await withThrowingTaskGroup(of: M.self) { group in
      for model in models {
        group.addTask { try await self.update(model) }
      }
      var updated: [M] = []
      for try await updatedModel in group {
        updated.append(updatedModel)
      }
      return updated
    }
  }

  func select<M: Model>(
    _ Model: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
    orderBy order: SQL.Order<M>? = nil,
    limit: Int? = nil,
    offset: Int? = nil,
    withSoftDeleted included: Bool = false,
  ) async throws -> [M] {
    let stmt = SQL.Statement.select(
      M.self,
      where: constraint + .withSoftDeleted(if: included),
      orderBy: order,
      limit: limit,
      offset: offset,
    )
    return try await execute(statement: stmt, returning: M.self)
  }

  func select<M: Model>(
    all _: M.Type,
    withSoftDeleted: Bool = false,
  ) async throws -> [M] {
    try await self.select(M.self, withSoftDeleted: withSoftDeleted)
  }

  func count<M: Model>(
    _: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
    withSoftDeleted included: Bool = false,
  ) async throws -> Int {
    let stmt = SQL.Statement.count(
      M.self,
      where: constraint + .withSoftDeleted(if: included),
    )
    let rows = try await execute(statement: stmt)
    guard rows.count == 1 else {
      throw DuetSQLError.notFound("\(M.self)")
    }
    let decoded = try rows[0].decode(model: Count.self)
    return decoded.count
  }

  @discardableResult
  func delete<M: Model>(
    _ Model: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
    orderBy order: SQL.Order<M>? = nil,
    limit: Int? = nil,
    offset: Int? = nil,
  ) async throws -> Int {
    if M.isSoftDeletable {
      let stmt = SQL.Statement.softDelete(
        M.self,
        where: constraint,
        orderBy: order,
        limit: limit,
        offset: offset,
      )
      let rows = try await execute(statement: stmt)
      return rows.count
    } else {
      return try await self.forceDelete(
        M.self,
        where: constraint,
        orderBy: order,
        limit: limit,
        offset: offset,
      )
    }
  }

  @discardableResult
  func forceDelete<M: Model>(
    _ Model: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
    orderBy order: SQL.Order<M>? = nil,
    limit: Int? = nil,
    offset: Int? = nil,
  ) async throws -> Int {
    let stmt = SQL.Statement.delete(
      M.self,
      where: constraint,
      orderBy: order,
      limit: limit,
      offset: offset,
    )
    let rows = try await execute(statement: stmt)
    return rows.count
  }

  @discardableResult
  func delete<M: Model>(
    _: M.Type,
    byId id: UUIDStringable,
    force: Bool = false,
  ) async throws -> Int {
    if M.isSoftDeletable, !force {
      let stmt = SQL.Statement.softDelete(
        M.self,
        where: .equals(M.ColumnName.id, .uuid(id)),
        orderBy: nil,
        limit: nil,
        offset: nil,
      )
      let rows = try await execute(statement: stmt)
      return rows.count
    } else {
      return try await self.forceDelete(
        M.self,
        where: .equals(M.ColumnName.id, .uuid(id)),
      )
    }
  }

  @discardableResult
  func delete<M: Model>(_ model: M, force: Bool = false) async throws -> M {
    try await self.delete(M.self, byId: model.id, force: force)
    return model
  }

  @discardableResult
  func delete<M: Model>(_ id: Tagged<M, UUID>, force: Bool = false) async throws -> Int {
    try await self.delete(M.self, byId: id, force: force)
  }

  func delete<M: Model>(all _: M.Type, force: Bool = false) async throws {
    if M.isSoftDeletable, !force {
      let stmt = SQL.Statement.softDelete(
        M.self,
        where: .always,
        orderBy: nil,
        limit: nil,
        offset: nil,
      )
      _ = try await self.execute(statement: stmt)
    } else {
      _ = try await self.forceDelete(M.self, where: .always)
    }
  }

  func customQuery<T: CustomQueryable>(
    _ Custom: T.Type,
    withBindings bindings: [Postgres.Data]? = nil,
  ) async throws -> [T] {
    let statement = Custom.query(bindings: bindings ?? [])
    let rows = try await self.execute(statement: statement)
    return try Custom.decode(from: rows)
  }
}

private struct Count: Decodable {
  var count: Int
}
