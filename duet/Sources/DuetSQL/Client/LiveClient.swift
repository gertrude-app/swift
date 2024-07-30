import FluentSQL

public struct LiveClient: Client {
  public let sql: SQLDatabase

  public init(sql: SQLDatabase) {
    self.sql = sql
  }

  @discardableResult
  public func create<M: Model>(_ models: [M]) async throws -> [M] {
    guard !models.isEmpty else { return models }
    let prepared = try SQL.insert(into: M.self, values: models.map(\.insertValues))
    try await SQL.execute(prepared, on: sql)
    return models
  }

  @discardableResult
  public func update<M: Model>(_ model: M) async throws -> M {
    var values = model.insertValues
    if let deletedAtCol = try? M.column("deleted_at"),
       let deletedAtAny = try? model.introspectValue(at: "deletedAt"),
       let deletedAt = deletedAtAny as? Date? {
      values[deletedAtCol] = .date(deletedAt)
    }
    let prepared = try SQL.update(
      M.self,
      set: values,
      where: M.column("id") == .id(model),
      returning: .all
    )
    let model = try await SQL.execute(prepared, on: sql)
      .compactMap { try $0.decode(M.self) }
      .first()
    return model
  }

  @discardableResult
  public func forceDelete<M: Model>(
    _: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
    orderBy: SQL.Order<M>? = nil,
    limit: Int? = nil,
    offset: Int? = nil
  ) async throws -> [M] {
    let models = try await query(M.self)
      .where(constraint)
      .orderBy(orderBy)
      .limit(limit)
      .offset(offset)
      .withSoftDeleted()
      .all()
    guard !models.isEmpty else { return models }
    let prepared = SQL.delete(from: M.self, where: constraint)
    try await SQL.execute(prepared, on: sql)
    return models
  }

  @discardableResult
  public func delete<M: Model>(
    _ Model: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
    orderBy order: SQL.Order<M>? = nil,
    limit: Int? = nil,
    offset: Int? = nil
  ) async throws -> [M] {
    let models = try await select(Model.self, where: constraint)
    let prepared: SQL.PreparedStatement
    if (try? M.column("deleted_at")) != nil {
      // @TODO should support order, limit
      prepared = SQL.softDelete(M.self, where: constraint)
    } else {
      prepared = SQL.delete(
        from: M.self,
        where: constraint,
        orderBy: order,
        limit: limit,
        offset: offset
      )
    }
    try await SQL.execute(prepared, on: sql)
    return models
  }

  public func select<M: Model>(
    _ Model: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
    orderBy: SQL.Order<M>? = nil,
    limit: Int? = nil,
    offset: Int? = nil,
    withSoftDeleted: Bool = false
  ) async throws -> [M] {
    let prepared = SQL.select(
      .all,
      from: M.self,
      where: constraint + (withSoftDeleted ? .always : .notSoftDeleted),
      orderBy: orderBy,
      limit: limit,
      offset: offset
    )
    let rows = try await SQL.execute(prepared, on: sql)
    return try rows.compactMap { try $0.decode(Model.self) }
  }

  public func customQuery<T: CustomQueryable>(
    _ Custom: T.Type,
    withBindings bindings: [Postgres.Data]? = nil
  ) async throws -> [T] {
    let query = Custom.query(numBindings: bindings?.count ?? 0)
    let prepared = SQL.PreparedStatement(query: query, bindings: bindings ?? [])
    let rows = try await SQL.execute(prepared, on: sql)
    return try Custom.decode(fromSqlRows: rows)
  }

  public func count<M: Model>(
    _: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
    withSoftDeleted: Bool = false
  ) async throws -> Int {
    let rows = try await SQL.execute(
      SQL.count(M.self, where: constraint + (withSoftDeleted ? .always : .notSoftDeleted)),
      on: sql
    )
    guard let row = rows.first else {
      throw DuetSQLError.notFound("\(M.self)")
    }
    let count = try row.decode(model: Count.self)
    return count.count
  }
}

private struct Count: Decodable {
  var count: Int
}
