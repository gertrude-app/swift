import DuetSQL
import TypescriptPairQL

struct DeleteUser: TypescriptPair {
  static var auth: ClientAuth = .admin
  typealias Input = UUID
}

// resolver

extension DeleteUser: PairResolver {
  static func resolve(for id: UUID, in context: AdminContext) async throws -> Output {
    try await Current.db.query(User.self)
      .where(.id == id)
      .where(.adminId == context.admin.id)
      .delete()
    return .success
  }
}
