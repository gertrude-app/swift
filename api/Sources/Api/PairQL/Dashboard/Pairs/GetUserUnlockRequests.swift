import DuetSQL
import PairQL

struct GetUserUnlockRequests: Pair {
  static var auth: ClientAuth = .admin
  typealias Input = User.Id
  typealias Output = [GetUnlockRequest.Output]
}

// resolver

extension GetUserUnlockRequests: Resolver {
  static func resolve(with id: User.Id, in context: AdminContext) async throws -> Output {
    let user = try await context.verifiedUser(from: id)
    let devices = try await Current.db.query(Device.self)
      .where(.userId == user.id)
      .all()
    let requests = try await Current.db.query(UnlockRequest.self)
      .where(.deviceId |=| devices.map { .id($0) })
      .all()

    // TODO: this is super inefficient, re-queries for same entities...
    return try await requests.concurrentMap { try await .init(from: $0, in: context) }
  }
}
