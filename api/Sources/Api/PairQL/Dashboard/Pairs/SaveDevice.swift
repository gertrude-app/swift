import DuetSQL
import Gertie
import PairQL

struct SaveDevice: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var id: Computer.Id
    var name: String?
    var releaseChannel: ReleaseChannel
  }
}

// resolver

extension SaveDevice: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    var device = try await context.db.find(input.id)
    device.customName = input.name
    device.appReleaseChannel = input.releaseChannel
    try await context.db.update(device)
    return .success
  }
}
