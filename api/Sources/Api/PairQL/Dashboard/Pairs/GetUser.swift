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
    var id: Api.Child.Id
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

  typealias Input = Api.Child.Id
  typealias Output = User
}

// resolver

extension GetUser: Resolver {
  static func resolve(
    with id: Api.Child.Id,
    in context: AdminContext
  ) async throws -> Output {
    try await Output(from: context.verifiedUser(from: id), in: context.db)
  }
}

// TODO: this is major N+1 territory, write a custom query w/ join for perf
// @see also ruleKeychains(for:in:)
func userKeychainSummaries(
  for childId: Child.Id,
  in db: any DuetSQL.Client
) async throws -> [UserKeychainSummary] {
  let childKeychains = try await ChildKeychain.query()
    .where(.childId == childId)
    .all(in: db)
  let keychains = try await Keychain.query()
    .where(.id |=| childKeychains.map(\.keychainId))
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
      schedule: childKeychains.first { $0.keychainId == keychain.id }?.schedule
    )
  }
}

extension GetUser.User {
  init(from child: Api.Child, in db: any DuetSQL.Client) async throws {
    async let childKeychains = userKeychainSummaries(for: child.id, in: db)
    let pairs = try await ComputerUser.query()
      .where(.childId == child.id)
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
      blockedApps = try await (child.blockedApps(in: db)).map(\.dto)
    }

    try await self.init(
      id: child.id,
      name: child.name,
      keyloggingEnabled: child.keyloggingEnabled,
      screenshotsEnabled: child.screenshotsEnabled,
      screenshotsResolution: child.screenshotsResolution,
      screenshotsFrequency: child.screenshotsFrequency,
      showSuspensionActivity: child.showSuspensionActivity,
      keychains: childKeychains,
      downtime: child.downtime,
      devices: devices.uniqued(on: \.id),
      blockedApps: blockedApps,
      createdAt: child.createdAt
    )
  }
}
