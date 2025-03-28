import Dependencies
import DuetSQL
import Foundation
import Gertie
import PairQL

struct UserKeychainSummary: PairNestable {
  var id: Api.Keychain.Id
  var parentId: Admin.Id
  var name: String
  var description: String?
  var isPublic: Bool
  var numKeys: Int
  var schedule: RuleSchedule?
}

struct GetUser: Pair {
  static let auth: ClientAuth = .parent

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
    var blockedApps: [UserBlockedApp.DTO]?
    var createdAt: Date
  }

  struct Device: PairNestable {
    var id: ComputerUser.Id
    var deviceId: Api.Device.Id
    var status: ChildComputerStatus
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
    .where(.childId == userId)
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
      parentId: keychain.parentId,
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
    let pairs = try await ComputerUser.query()
      .where(.childId == user.id)
      .all(in: db)
      .concurrentMap { (userDevice: ComputerUser) -> (GetUser.Device, Semver) in
        let adminDevice = try await userDevice.adminDevice(in: db)
        return await (GetUser.Device(
          id: userDevice.id,
          deviceId: adminDevice.id,
          status: userDevice.status(),
          modelFamily: adminDevice.model.family,
          modelTitle: adminDevice.model.shortDescription,
          modelIdentifier: adminDevice.model.identifier,
          customName: adminDevice.customName
        ), adminDevice.filterVersion ?? .zero)
      }
    let devices = pairs.map(\.0)
    let versions = pairs.map(\.1)

    var blockedApps: [UserBlockedApp.DTO]?
    if versions.contains(where: { $0 >= .init("2.6.0")! }) {
      blockedApps = try await (user.blockedApps(in: db)).map(\.dto)
    }

    try await self.init(
      id: user.id,
      name: user.name,
      keyloggingEnabled: user.keyloggingEnabled,
      screenshotsEnabled: user.screenshotsEnabled,
      screenshotsResolution: user.screenshotsResolution,
      screenshotsFrequency: user.screenshotsFrequency,
      showSuspensionActivity: user.showSuspensionActivity,
      keychains: userKeychains,
      downtime: user.downtime,
      devices: devices.uniqued(on: \.id),
      blockedApps: blockedApps,
      createdAt: user.createdAt
    )
  }
}
