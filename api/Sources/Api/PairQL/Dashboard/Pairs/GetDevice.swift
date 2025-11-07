import Dependencies
import DuetSQL
import Foundation
import Gertie
import PairQL

struct GetDevice: Pair {
  static let auth: ClientAuth = .parent

  typealias Input = UUID

  struct Output: PairOutput {
    struct User: PairNestable {
      var id: Api.Child.Id
      var name: String
      var status: ChildComputerStatus
    }

    var id: Computer.Id
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
  static func resolve(with id: UUID, in context: ParentContext) async throws -> Output {
    let computer = try await Computer.query()
      .where(.id == id)
      .where(.parentId == context.parent.id)
      .first(in: context.db)

    let computerUsers = try await computer.computerUsers(in: context.db)

    // this is a little hinky, should simplify when we handle
    // https://github.com/gertrude-app/project/issues/164
    var appVersion = Semver("0.0.0")
    for userDevice in computerUsers {
      if let version = Semver(userDevice.appVersion), version > appVersion {
        appVersion = version
      }
    }

    if computer.model.identifier == "unknown" {
      await with(dependency: \.slack)
        .error("unknown mac model identifier `\(computer.modelIdentifier)`")
    }

    @Dependency(\.websockets) var websockets

    return try await .init(
      id: computer.id,
      name: computer.customName,
      releaseChannel: computer.appReleaseChannel,
      users: computerUsers.concurrentMap { userDevice in
        try await .init(
          id: userDevice.childId,
          name: (userDevice.child(in: context.db)).name,
          status: websockets.status(userDevice.id),
        )
      },
      appVersion: appVersion.description,
      serialNumber: computer.serialNumber,
      modelIdentifier: computer.modelIdentifier,
      modelFamily: computer.model.family,
      modelTitle: computer.model.shortDescription,
    )
  }
}
