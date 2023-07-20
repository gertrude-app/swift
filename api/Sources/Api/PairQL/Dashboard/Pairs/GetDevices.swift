import Foundation
import PairQL

struct GetDevices: Pair {
  static var auth: ClientAuth = .admin
  typealias Output = [GetDevice.Output]
}

// resolver

extension GetDevices: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    let devices = try await context.admin.devices()
    return try await devices.concurrentMap { device in
      try await GetDevice.resolve(with: device.id.rawValue, in: context)
    }
  }
}
