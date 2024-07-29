import DuetSQL
import PairQL

struct GetUserUnlockRequests: Pair {
  static let auth: ClientAuth = .admin
  typealias Input = User.Id
  typealias Output = [GetUnlockRequest.Output]
}

// resolver

extension GetUserUnlockRequests: Resolver {
  static func resolve(with id: User.Id, in context: AdminContext) async throws -> Output {
    let user = try await context.verifiedUser(from: id)
    let userDevices = try await user.devices()
    let requests = try await Current.db.query(UnlockRequest.self)
      .where(.userDeviceId |=| userDevices.map { .id($0) })
      .all()

    // TODO: this is super inefficient, re-queries for same entities...
    return try await requests.concurrentMap { try await .init(from: $0, in: context) }
  }
}
