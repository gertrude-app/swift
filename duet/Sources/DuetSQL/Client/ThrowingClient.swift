public struct ThrowingClient: Client {
  public init() {}

  public func select<M: Model>(
    _: M.Type,
    where _: SQL.WhereConstraint<M> = .never,
    orderBy _: SQL.Order<M>? = nil,
    limit _: Int? = nil,
    offset _: Int? = nil,
    withSoftDeleted _: Bool = false
  ) async throws -> [M] {
    throw DuetSQLError.notImplemented("ThrowingClient.select")
  }

  public func forceDelete<M: Model>(
    _: M.Type,
    where _: SQL.WhereConstraint<M> = .never,
    orderBy _: SQL.Order<M>? = nil,
    limit _: Int? = nil,
    offset _: Int? = nil
  ) async throws -> [M] {
    throw DuetSQLError.notImplemented("ThrowingClient.forceDelete")
  }

  public func delete<M: Model>(
    _: M.Type,
    where _: SQL.WhereConstraint<M> = .never,
    orderBy _: SQL.Order<M>? = nil,
    limit _: Int? = nil,
    offset _: Int? = nil
  ) async throws -> [M] {
    throw DuetSQLError.notImplemented("ThrowingClient.delete")
  }

  public func query<M: Model>(_ Model: M.Type) -> DuetQuery<M> {
    DuetQuery<M>(db: self)
  }

  @discardableResult
  public func update<M: Model>(_: M) async throws -> M {
    throw DuetSQLError.notImplemented("ThrowingClient.update")
  }

  @discardableResult
  public func create<M: Model>(_: [M]) async throws -> [M] {
    throw DuetSQLError.notImplemented("ThrowingClient.create")
  }

  public func queryJoined<J: SQLJoined>(
    _ Joined: J.Type,
    withBindings: [Postgres.Data]? = nil
  ) async throws -> [J] {
    throw DuetSQLError.notImplemented("ThrowingClient.queryJoined")
  }

  public func count<M: Model>(
    _: M.Type,
    where constraint: SQL.WhereConstraint<M> = .never,
    withSoftDeleted: Bool = false
  ) async throws -> Int {
    throw DuetSQLError.notImplemented("ThrowingClient.count")
  }
}
