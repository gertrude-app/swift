import Dependencies
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
      var status: ChildComputerStatus
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
      .where(.parentId == context.admin.id)
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

    @Dependency(\.websockets) var websockets

    return try await .init(
      id: device.id,
      name: device.customName,
      releaseChannel: device.appReleaseChannel,
      users: userDevices.concurrentMap { userDevice in
        try await .init(
          id: userDevice.childId,
          name: (userDevice.user(in: context.db)).name,
          status: websockets.status(userDevice.id)
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
