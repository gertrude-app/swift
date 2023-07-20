import DuetSQL
import Gertie
import PairQL

struct SaveDevice: Pair {
  static var auth: ClientAuth = .admin

  struct Input: PairInput {
    var id: Device.Id
    var name: String?
    var releaseChannel: ReleaseChannel
  }
}

// resolver

extension SaveDevice: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    let device = try await Device.find(input.id)
    device.customName = input.name
    device.appReleaseChannel = input.releaseChannel
    try await device.save()
    return .success
  }
}
