public protocol SQLMutating: Sendable {
  @discardableResult
  func create<M: Model>(_ models: [M]) async throws -> [M]

  @discardableResult
  func update<M: Model>(_ model: M) async throws -> M

  @discardableResult
  func delete<M: Model>(
    _ Model: M.Type,
    where constraints: SQL.WhereConstraint<M>,
    orderBy order: SQL.Order<M>?,
    limit: Int?,
    offset: Int?
  ) async throws -> [M]

  @discardableResult
  func forceDelete<M: Model>(
    _ Model: M.Type,
    where: SQL.WhereConstraint<M>,
    orderBy: SQL.Order<M>?,
    limit: Int?,
    offset: Int?
  ) async throws -> [M]
}

public extension SQLMutating {
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
}
