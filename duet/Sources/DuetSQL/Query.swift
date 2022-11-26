import Duet

public struct DuetQuery<M: Model> {
  public let db: Client
  public let constraint: SQL.WhereConstraint<M>
  public let order: SQL.Order<M>?
  public let limit: Int?
  public let offset: Int?
  public let _withSoftDeleted: Bool

  public init(
    db: Client,
    constraint: SQL.WhereConstraint<M> = .always,
    order: SQL.Order<M>? = nil,
    limit: Int? = nil,
    offset: Int? = nil,
    withSoftDeleted: Bool = false
  ) {
    self.db = db
    self.constraint = constraint
    self.limit = limit
    self.order = order
    self.offset = offset
    _withSoftDeleted = withSoftDeleted
  }

  public func byId(_ id: UUIDStringable, withSoftDeleted: Bool = false) throws -> DuetQuery<M> {
    try .init(
      db: db,
      constraint: constraint + (M.column("id") == .uuid(id)),
      order: order,
      limit: limit,
      offset: offset,
      withSoftDeleted: withSoftDeleted
    )
  }

  public func withSoftDeleted() -> DuetQuery<M> {
    .init(
      db: db,
      constraint: constraint,
      order: order,
      limit: limit,
      offset: offset,
      withSoftDeleted: true
    )
  }

  public func `where`(_ constraint: SQL.WhereConstraint<M>) -> DuetQuery<M> {
    .init(
      db: db,
      constraint: self.constraint + constraint,
      order: order,
      limit: limit,
      offset: offset,
      withSoftDeleted: _withSoftDeleted
    )
  }

  public func limit(_ limit: Int?) -> DuetQuery<M> {
    .init(
      db: db,
      constraint: constraint,
      order: order,
      limit: limit,
      offset: offset,
      withSoftDeleted: _withSoftDeleted
    )
  }

  public func offset(_ offset: Int?) -> DuetQuery<M> {
    .init(
      db: db,
      constraint: constraint,
      order: order,
      limit: limit,
      offset: offset,
      withSoftDeleted: _withSoftDeleted
    )
  }

  public func orderBy(_ order: SQL.Order<M>?) -> DuetQuery<M> {
    .init(
      db: db,
      constraint: constraint,
      order: order,
      limit: limit,
      offset: offset,
      withSoftDeleted: _withSoftDeleted
    )
  }

  public func orderBy(_ column: M.ColumnName, _ direction: SQL.OrderDirection) -> DuetQuery<M> {
    .init(
      db: db,
      constraint: constraint,
      order: .init(column: column, direction: direction),
      limit: limit,
      offset: offset,
      withSoftDeleted: _withSoftDeleted
    )
  }

  @discardableResult
  public func delete(force: Bool = false) async throws -> [M] {
    if force || _withSoftDeleted {
      return try await db.forceDelete(
        M.self,
        where: constraint,
        orderBy: order,
        limit: limit,
        offset: offset
      )
    } else {
      return try await db.delete(
        M.self,
        where: constraint,
        orderBy: order,
        limit: limit,
        offset: offset
      )
    }
  }

  @discardableResult
  public func deleteOne(force: Bool = false) async throws -> M {
    let models = try await db.select(
      M.self,
      where: constraint,
      orderBy: order,
      limit: limit,
      offset: offset,
      withSoftDeleted: force || _withSoftDeleted
    )
    guard !models.isEmpty else { throw DuetSQLError.notFound }
    guard models.count == 1 else { throw DuetSQLError.tooManyResultsForDeleteOne }
    if force {
      try await db.forceDelete(
        M.self,
        where: constraint,
        orderBy: order,
        limit: limit,
        offset: offset
      )
    } else {
      try await db.delete(M.self, where: constraint, orderBy: order, limit: limit, offset: offset)
    }
    return models.first!
  }

  public func all() async throws -> [M] {
    try await db.select(
      M.self,
      where: constraint,
      orderBy: order,
      limit: limit,
      offset: offset,
      withSoftDeleted: _withSoftDeleted
    )
  }

  public func firstOrThrowNotFound() async throws -> M {
    try await all().firstOrThrowNotFound()
  }

  public func first() async throws -> M {
    try await all().firstOrThrowNotFound()
  }

  public func firstOrThrow(_ error: Error) async throws -> M {
    try await all().firstOrThrow(error)
  }

  public func count() async throws -> Int {
    try await db.count(M.self, where: constraint, withSoftDeleted: _withSoftDeleted)
  }
}
