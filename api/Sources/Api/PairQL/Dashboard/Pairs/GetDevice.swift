import DuetSQL
import Foundation
import Gertie
import PairQL

struct GetDevice: Pair {
  static let auth: ClientAuth = .admin

  typealias Input = UUID

  struct Output: PairOutput {
    struct User: PairNestable {
      var id: Api.User.Id
      var name: String
      var isOnline: Bool
    }

    var id: Device.Id
    var name: String?
    var releaseChannel: ReleaseChannel
    var users: [User]
    var appVersion: String
    var serialNumber: String
    var modelIdentifier: String
    let modelFamily: DeviceModelFamily
    let modelTitle: String
  }
}

// resolver

extension GetDevice: Resolver {
  static func resolve(with id: UUID, in context: AdminContext) async throws -> Output {
    let device = try await Device.query()
      .where(.id == id)
      .where(.adminId == context.admin.id)
      .first(in: context.db)

    let userDevices = try await device.userDevices(in: context.db)

    // this is a little hinky, should simplify when we handle
    // https://github.com/gertrude-app/project/issues/164
    var appVersion = Semver("0.0.0")
    for userDevice in userDevices {
      if let version = Semver(userDevice.appVersion), version > appVersion {
        appVersion = version
      }
    }

    return await .init(
      id: device.id,
      name: device.customName,
      releaseChannel: device.appReleaseChannel,
      users: try userDevices.concurrentMap { userDevice in
        .init(
          id: userDevice.userId,
          name: (try await userDevice.user(in: context.db)).name,
          isOnline: await userDevice.isOnline()
        )
      },
      appVersion: appVersion.description,
      serialNumber: device.serialNumber,
      modelIdentifier: device.modelIdentifier,
      modelFamily: device.model.family,
      modelTitle: device.model.shortDescription
    )
  }
}
