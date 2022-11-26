import Duet
import Tagged

public protocol Client: SQLQuerying, SQLMutating {
  func query<M: Model>(_ Model: M.Type) -> DuetQuery<M>

  @discardableResult
  func update<M: Model>(_ model: M) async throws -> M

  @discardableResult
  func create<M: Model>(_ models: [M]) async throws -> [M]

  func queryJoined<J: SQLJoined>(
    _ Joined: J.Type,
    withBindings: [Postgres.Data]?
  ) async throws -> [J]
}

public extension Client {
  func query<M: Model>(_: M.Type) -> DuetQuery<M> {
    DuetQuery<M>(db: self)
  }

  func find<M: Model>(_: M.Type, byId id: UUID, withSoftDeleted: Bool = false) async throws -> M {
    try await query(M.self).byId(id, withSoftDeleted: withSoftDeleted).first()
  }

  func find<M: Model>(_ id: Tagged<M, UUID>, withSoftDeleted: Bool = false) async throws -> M {
    try await query(M.self).byId(id, withSoftDeleted: withSoftDeleted).first()
  }

  func find<M: Model>(
    _: M.Type,
    byId id: M.IdValue,
    withSoftDeleted: Bool = false
  ) async throws -> M {
    try await query(M.self).byId(id, withSoftDeleted: withSoftDeleted).first()
  }

  @discardableResult
  func create<M: Model>(_ model: M) async throws -> M {
    let models = try await create([model])
    return models.first ?? model
  }

  @discardableResult
  func delete<M: Model>(
    _: M.Type,
    byId id: UUIDStringable,
    force: Bool = false
  ) async throws -> M {
    try await query(M.self).where(M.column("id") == id).deleteOne(force: force)
  }

  @discardableResult
  func delete<M: Model>(_ id: Tagged<M, UUID>, force: Bool = false) async throws -> M {
    try await query(M.self).where(M.column("id") == id).deleteOne(force: force)
  }

  func deleteAll<M: Model>(_: M.Type, force: Bool = false) async throws {
    _ = try await query(M.self).delete(force: force)
  }
}
