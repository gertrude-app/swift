import DuetSQL
import Foundation
import Gertie
import PairQL

struct KeychainSummary: PairNestable {
  let id: Api.Keychain.Id
  let authorId: Admin.Id
  let name: String
  let description: String?
  let isPublic: Bool
  let numKeys: Int
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
    var keychains: [KeychainSummary]
    var devices: [Device]
    var createdAt: Date
  }

  struct Device: PairNestable {
    let id: Api.Device.Id
    let isOnline: Bool
    let modelFamily: DeviceModelFamily
    let modelTitle: String
    let modelIdentifier: String
    let customName: String?
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
    try await Output(from: context.verifiedUser(from: id))
  }
}

extension KeychainSummary {
  init(from keychain: Keychain) async throws {
    let numKeys = try await Current.db.count(
      Key.self,
      where: .keychainId == keychain.id,
      withSoftDeleted: false
    )
    self.init(
      id: keychain.id,
      authorId: keychain.authorId,
      name: keychain.name,
      description: keychain.description,
      isPublic: keychain.isPublic,
      numKeys: numKeys
    )
  }
}

extension GetUser.User {
  init(from user: Api.User) async throws {
    async let userKeychains = user.keychains()
      .concurrentMap { try await KeychainSummary(from: $0) }

    async let devices = Current.db.query(UserDevice.self)
      .where(.userId == user.id)
      .all()
      .concurrentMap { userDevice in
        let adminDevice = try await userDevice.adminDevice()
        return GetUser.Device(
          id: adminDevice.id,
          isOnline: await userDevice.isOnline(),
          modelFamily: adminDevice.model.family,
          modelTitle: adminDevice.model.shortDescription,
          modelIdentifier: adminDevice.model.identifier,
          customName: adminDevice.customName
        )
      }

    self.init(
      id: user.id,
      name: user.name,
      keyloggingEnabled: user.keyloggingEnabled,
      screenshotsEnabled: user.screenshotsEnabled,
      screenshotsResolution: user.screenshotsResolution,
      screenshotsFrequency: user.screenshotsFrequency,
      showSuspensionActivity: user.showSuspensionActivity,
      keychains: try await userKeychains,
      devices: try await devices,
      createdAt: user.createdAt
    )
  }
}
