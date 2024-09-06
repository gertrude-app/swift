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
    DuetQuery<M>(db: self)
  }

  func find<M: Model>(_: M.Type, byId id: UUID, withSoftDeleted: Bool = false) async throws -> M {
    try await self.query(M.self).byId(id, withSoftDeleted: withSoftDeleted).first()
  }

  func find<M: Model>(_ id: Tagged<M, UUID>, withSoftDeleted: Bool = false) async throws -> M {
    try await self.query(M.self).byId(id, withSoftDeleted: withSoftDeleted).first()
  }

  func find<M: Model>(
    _: M.Type,
    byId id: M.IdValue,
    withSoftDeleted: Bool = false
  ) async throws -> M {
    try await self.query(M.self).byId(id, withSoftDeleted: withSoftDeleted).first()
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
    try await withThrowingTaskGroup(of: M.self) { group in
      for model in models {
        group.addTask { try await update(model) }
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
    withSoftDeleted included: Bool = false
  ) async throws -> [M] {
    let stmt = SQL.Statement.select(
      M.self,
      where: constraint + .withSoftDeleted(if: included),
      orderBy: order,
      limit: limit,
      offset: offset
    )
    return try await execute(statement: stmt, returning: M.self)
  }

  func count<M: Model>(
    _: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
    withSoftDeleted: Bool = false
  ) async throws -> Int {
    let stmt = SQL.Statement.count(M.self, where: constraint)
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
    offset: Int? = nil
  ) async throws -> Int {
    let stmt: SQL.Statement
    if M.isSoftDeletable {
      stmt = SQL.Statement.softDelete(
        M.self,
        where: constraint,
        orderBy: order,
        limit: limit,
        offset: offset
      )
    } else {
      stmt = SQL.Statement.delete(
        M.self,
        where: constraint,
        orderBy: order,
        limit: limit,
        offset: offset
      )
    }
    let rows = try await execute(statement: stmt)
    return rows.count
  }

  @discardableResult
  func forceDelete<M: Model>(
    _ Model: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
    orderBy order: SQL.Order<M>? = nil,
    limit: Int? = nil,
    offset: Int? = nil
  ) async throws -> Int {
    let stmt = SQL.Statement.delete(
      M.self,
      where: constraint,
      orderBy: order,
      limit: limit,
      offset: offset
    )
    let rows = try await execute(statement: stmt)
    return rows.count
  }

  @discardableResult
  func delete<M: Model>(
    _: M.Type,
    byId id: UUIDStringable,
    force: Bool = false
  ) async throws -> M {
    try await self.query(M.self).where(M.column("id") == id).deleteOne(force: force)
  }

  @discardableResult
  func delete<M: Model>(_ id: Tagged<M, UUID>, force: Bool = false) async throws -> M {
    try await self.query(M.self).where(M.column("id") == id).deleteOne(force: force)
  }

  func deleteAll<M: Model>(_: M.Type, force: Bool = false) async throws {
    _ = try await self.query(M.self).delete(force: force)
  }

  func customQuery<T: CustomQueryable>(
    _ Custom: T.Type,
    withBindings bindings: [Postgres.Data]? = nil
  ) async throws -> [T] {
    let query = Custom.query(bindings: bindings ?? [])
    let rows = try await self.execute(raw: query)
    return try Custom.decode(from: rows)
  }
}

private struct Count: Decodable {
  var count: Int
}
