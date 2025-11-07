import DuetSQL
import Foundation
import Gertie
import PairQL

struct IOSDevices: Pair {
  static let auth: ClientAuth = .parent

  struct OutputDevice: PairOutput {
    var id: IOSApp.Device.Id
    var childName: String
    var deviceType: String
    var osVersion: String
  }

  typealias Output = [OutputDevice]
}

extension IOSDevices: NoInputResolver {
  static func resolve(in ctx: ParentContext) async throws -> Output {
    let children = try await ctx.children()
    let devices = try await IOSApp.Device.query()
      .where(.childId |=| children.map(\.id))
      .all(in: ctx.db)
    return devices.map { device in
      OutputDevice(
        id: device.id,
        childName: children.first(where: { $0.id == device.childId })?.name ?? "Unknown",
        deviceType: device.deviceType,
        osVersion: device.iosVersion,
      )
    }
  }
}
