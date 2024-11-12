import Dependencies
import DuetSQL
import Foundation
import Gertie
import PairQL

struct UserKeychainSummary: PairNestable {
  var id: Api.Keychain.Id
  var authorId: Admin.Id
  var name: String
  var description: String?
  var isPublic: Bool
  var numKeys: Int
  var schedule: KeychainSchedule?
}

struct GetUser: Pair {
  static let auth: ClientAuth = .admin

  struct User: PairOutput {
    var id: Api.User.Id
    var name: String
    var keyloggingEnabled: Bool
    var screenshotsEnabled: Bool
    var screenshotsResolution: Int
    var screenshotsFrequency: Int
    var showSuspensionActivity: Bool
    var keychains: [UserKeychainSummary]
    var downtime: PlainTimeWindow?
    var devices: [Device]
    var canUseTimeFeatures: Bool
    var createdAt: Date
  }

  struct Device: PairNestable {
    var id: Api.Device.Id
    var isOnline: Bool
    var modelFamily: DeviceModelFamily
    var modelTitle: String
    var modelIdentifier: String
    var customName: String?
  }

  typealias Input = Api.User.Id
  typealias Output = User
}

// resolver

extension GetUser: Resolver {
  static func resolve(
    with id: Api.User.Id,
    in context: AdminContext
  ) async throws -> Output {
    try await Output(from: context.verifiedUser(from: id), in: context.db)
  }
}

// TODO: this is major N+1 territory, write a custom query w/ join for perf
// @see also ruleKeychains(for:in:)
func userKeychainSummaries(
  for userId: User.Id,
  in db: any DuetSQL.Client
) async throws -> [UserKeychainSummary] {
  let userKeychains = try await UserKeychain.query()
    .where(.userId == userId)
    .all(in: db)
  let keychains = try await Keychain.query()
    .where(.id |=| userKeychains.map(\.keychainId))
    .all(in: db)
  return try await keychains.concurrentMap { keychain in
    let numKeys = try await db.count(
      Key.self,
      where: .keychainId == keychain.id,
      withSoftDeleted: false
    )
    return .init(
      id: keychain.id,
      authorId: keychain.authorId,
      name: keychain.name,
      description: keychain.description,
      isPublic: keychain.isPublic,
      numKeys: numKeys,
      schedule: userKeychains.first { $0.keychainId == keychain.id }?.schedule
    )
  }
}

extension GetUser.User {
  init(from user: Api.User, in db: any DuetSQL.Client) async throws {
    async let userKeychains = userKeychainSummaries(for: user.id, in: db)
    let pairs = try await UserDevice.query()
      .where(.userId == user.id)
      .all(in: db)
      .concurrentMap { (userDevice: UserDevice) -> (GetUser.Device, Semver) in
        let adminDevice = try await userDevice.adminDevice(in: db)
        return (GetUser.Device(
          id: adminDevice.id,
          isOnline: await userDevice.isOnline(),
          modelFamily: adminDevice.model.family,
          modelTitle: adminDevice.model.shortDescription,
          modelIdentifier: adminDevice.model.identifier,
          customName: adminDevice.customName
        ), adminDevice.filterVersion ?? .zero)
      }
    let devices = pairs.map(\.0)
    let versions = pairs.map(\.1)

    self.init(
      id: user.id,
      name: user.name,
      keyloggingEnabled: user.keyloggingEnabled,
      screenshotsEnabled: user.screenshotsEnabled,
      screenshotsResolution: user.screenshotsResolution,
      screenshotsFrequency: user.screenshotsFrequency,
      showSuspensionActivity: user.showSuspensionActivity,
      keychains: try await userKeychains,
      downtime: user.downtime,
      devices: devices.uniqued(on: \.id),
      canUseTimeFeatures: versions.contains(where: { $0 >= .init("2.5.0")! }),
      createdAt: user.createdAt
    )
  }
}
