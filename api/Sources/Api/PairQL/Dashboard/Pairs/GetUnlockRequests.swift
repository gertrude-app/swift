import DuetSQL
import PairQL

struct GetUnlockRequests: Pair {
  static var auth: ClientAuth = .admin
  typealias Output = [GetUnlockRequest.Output]
}

// resolver

extension GetUnlockRequests: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    let users = try await Current.db.query(User.self)
      .where(.adminId == context.admin.id)
      .all()
    let devices = try await Current.db.query(Device.self)
      .where(.userId |=| users.map { .id($0) })
      .all()
    let requests = try await Current.db.query(UnlockRequest.self)
      .where(.deviceId |=| devices.map { .id($0) })
      .all()

    // TODO: this is super inefficient, re-queries for same entities...
    return try await requests.concurrentMap { try await .init(from: $0, in: context) }
  }
}
