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
    self._withSoftDeleted = withSoftDeleted
  }

  public func byId(_ id: UUIDStringable, withSoftDeleted: Bool = false) throws -> DuetQuery<M> {
    try .init(
      db: self.db,
      constraint: self.constraint + (M.column("id") == .uuid(id)),
      order: self.order,
      limit: self.limit,
      offset: self.offset,
      withSoftDeleted: withSoftDeleted
    )
  }

  public func withSoftDeleted() -> DuetQuery<M> {
    .init(
      db: self.db,
      constraint: self.constraint,
      order: self.order,
      limit: self.limit,
      offset: self.offset,
      withSoftDeleted: true
    )
  }

  public func `where`(_ constraint: SQL.WhereConstraint<M>) -> DuetQuery<M> {
    .init(
      db: self.db,
      constraint: self.constraint + constraint,
      order: self.order,
      limit: self.limit,
      offset: self.offset,
      withSoftDeleted: self._withSoftDeleted
    )
  }

  public func limit(_ limit: Int?) -> DuetQuery<M> {
    .init(
      db: self.db,
      constraint: self.constraint,
      order: self.order,
      limit: limit,
      offset: self.offset,
      withSoftDeleted: self._withSoftDeleted
    )
  }

  public func offset(_ offset: Int?) -> DuetQuery<M> {
    .init(
      db: self.db,
      constraint: self.constraint,
      order: self.order,
      limit: self.limit,
      offset: offset,
      withSoftDeleted: self._withSoftDeleted
    )
  }

  public func orderBy(_ order: SQL.Order<M>?) -> DuetQuery<M> {
    .init(
      db: self.db,
      constraint: self.constraint,
      order: order,
      limit: self.limit,
      offset: self.offset,
      withSoftDeleted: self._withSoftDeleted
    )
  }

  public func orderBy(_ column: M.ColumnName, _ direction: SQL.OrderDirection) -> DuetQuery<M> {
    .init(
      db: self.db,
      constraint: self.constraint,
      order: .init(column: column, direction: direction),
      limit: self.limit,
      offset: self.offset,
      withSoftDeleted: self._withSoftDeleted
    )
  }

  @discardableResult
  public func delete(force: Bool = false) async throws -> [M] {
    if force || self._withSoftDeleted {
      return try await self.db.forceDelete(
        M.self,
        where: self.constraint,
        orderBy: self.order,
        limit: self.limit,
        offset: self.offset
      )
    } else {
      return try await self.db.delete(
        M.self,
        where: self.constraint,
        orderBy: self.order,
        limit: self.limit,
        offset: self.offset
      )
    }
  }

  @discardableResult
  public func deleteOne(force: Bool = false) async throws -> M {
    let models = try await db.select(
      M.self,
      where: self.constraint,
      orderBy: self.order,
      limit: self.limit,
      offset: self.offset,
      withSoftDeleted: force || self._withSoftDeleted
    )
    guard !models.isEmpty else { throw DuetSQLError.notFound("\(M.self)") }
    guard models.count == 1 else { throw DuetSQLError.tooManyResultsForDeleteOne }
    if force {
      try await self.db.forceDelete(
        M.self,
        where: self.constraint,
        orderBy: self.order,
        limit: self.limit,
        offset: self.offset
      )
    } else {
      try await self.db.delete(
        M.self,
        where: self.constraint,
        orderBy: self.order,
        limit: self.limit,
        offset: self.offset
      )
    }
    return models.first!
  }

  public func all() async throws -> [M] {
    try await self.db.select(
      M.self,
      where: self.constraint,
      orderBy: self.order,
      limit: self.limit,
      offset: self.offset,
      withSoftDeleted: self._withSoftDeleted
    )
  }

  public func first(orThrow error: Error = DuetSQLError.notFound("\(M.self)")) async throws -> M {
    try await self.all().first(orThrow: error)
  }

  public func count() async throws -> Int {
    try await self.db.count(M.self, where: self.constraint, withSoftDeleted: self._withSoftDeleted)
  }
}
