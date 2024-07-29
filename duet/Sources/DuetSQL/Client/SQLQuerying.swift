public protocol SQLQuerying: Sendable {
  func select<M: Model>(
    _ Model: M.Type,
    where: SQL.WhereConstraint<M>,
    orderBy: SQL.Order<M>?,
    limit: Int?,
    offset: Int?,
    withSoftDeleted: Bool
  ) async throws -> [M]

  func count<M: Model>(
    _: M.Type,
    where: SQL.WhereConstraint<M>,
    withSoftDeleted: Bool
  ) async throws -> Int
}
