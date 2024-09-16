import DuetSQL
import MacAppRoute

extension GetAccountStatus: NoInputResolver {
  static func resolve(in context: UserContext) async throws -> Output {
    let admin = try await context.user.admin(in: context.db)
    return .init(status: admin.accountStatus)
  }
}
