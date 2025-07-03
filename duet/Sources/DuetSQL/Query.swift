import Duet

public struct DuetQuery<M: Model>: Sendable {
  public let constraint: SQL.WhereConstraint<M>
  public let order: SQL.Order<M>?
  public let limit: Int?
  public let offset: Int?
  public let _withSoftDeleted: Bool

  public init(
    constraint: SQL.WhereConstraint<M> = .always,
    order: SQL.Order<M>? = nil,
    limit: Int? = nil,
    offset: Int? = nil,
    withSoftDeleted: Bool = false
  ) {
    self.constraint = constraint
    self.limit = limit
    self.order = order
    self.offset = offset
    self._withSoftDeleted = withSoftDeleted
  }

  public func byId(_ id: UUIDStringable, withSoftDeleted: Bool = false) throws -> DuetQuery<M> {
    try .init(
      constraint: self.constraint + (M.column("id") == .uuid(id)),
      order: self.order,
      limit: self.limit,
      offset: self.offset,
      withSoftDeleted: withSoftDeleted
    )
  }

  public func withSoftDeleted() -> DuetQuery<M> {
    .init(
      constraint: self.constraint,
      order: self.order,
      limit: self.limit,
      offset: self.offset,
      withSoftDeleted: true
    )
  }

  public func `where`(_ constraint: SQL.WhereConstraint<M>) -> DuetQuery<M> {
    .init(
      constraint: self.constraint + constraint,
      order: self.order,
      limit: self.limit,
      offset: self.offset,
      withSoftDeleted: self._withSoftDeleted
    )
  }

  public func limit(_ limit: Int?) -> DuetQuery<M> {
    .init(
      constraint: self.constraint,
      order: self.order,
      limit: limit,
      offset: self.offset,
      withSoftDeleted: self._withSoftDeleted
    )
  }

  public func offset(_ offset: Int?) -> DuetQuery<M> {
    .init(
      constraint: self.constraint,
      order: self.order,
      limit: self.limit,
      offset: offset,
      withSoftDeleted: self._withSoftDeleted
    )
  }

  public func orderBy(_ order: SQL.Order<M>?) -> DuetQuery<M> {
    .init(
      constraint: self.constraint,
      order: order,
      limit: self.limit,
      offset: self.offset,
      withSoftDeleted: self._withSoftDeleted
    )
  }

  public func orderBy(_ column: M.ColumnName, _ direction: SQL.OrderDirection) -> DuetQuery<M> {
    .init(
      constraint: self.constraint,
      order: .init(column: column, direction: direction),
      limit: self.limit,
      offset: self.offset,
      withSoftDeleted: self._withSoftDeleted
    )
  }

  @discardableResult
  public func delete(in db: any DuetSQL.Client, force: Bool = false) async throws -> Int {
    if force || self._withSoftDeleted {
      try await db.forceDelete(
        M.self,
        where: self.constraint,
        orderBy: self.order,
        limit: self.limit,
        offset: self.offset
      )
    } else {
      try await db.delete(
        M.self,
        where: self.constraint,
        orderBy: self.order,
        limit: self.limit,
        offset: self.offset
      )
    }
  }

  @discardableResult
  public func deleteOne(in db: any DuetSQL.Client, force: Bool = false) async throws -> M {
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
      try await db.forceDelete(
        M.self,
        where: self.constraint,
        orderBy: self.order,
        limit: self.limit,
        offset: self.offset
      )
    } else {
      try await db.delete(
        M.self,
        where: self.constraint,
        orderBy: self.order,
        limit: self.limit,
        offset: self.offset
      )
    }
    return models.first!
  }

  public func all(in db: any DuetSQL.Client) async throws -> [M] {
    try await db.select(
      M.self,
      where: self.constraint,
      orderBy: self.order,
      limit: self.limit,
      offset: self.offset,
      withSoftDeleted: self._withSoftDeleted
    )
  }

  public func first(
    in db: any DuetSQL.Client,
    orThrow error: Error = DuetSQLError.notFound("\(M.self)")
  ) async throws -> M {
    guard let first = try await self.all(in: db).first else {
      throw error
    }
    return first
  }

  public func count(in db: any DuetSQL.Client) async throws -> Int {
    try await db.count(M.self, where: self.constraint, withSoftDeleted: self._withSoftDeleted)
  }
}
