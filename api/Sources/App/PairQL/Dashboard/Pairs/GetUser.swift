import DuetSQL
import Foundation
import Shared
import TypescriptPairQL

struct GetUser: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Device: Equatable, Codable, TypescriptRepresentable {
    let id: App.Device.Id
    let isOnline: Bool
    let modelFamily: DeviceModelFamily
    let modelTitle: String
  }

  struct Keychain: Equatable, Codable, TypescriptRepresentable {
    let id: App.Keychain.Id
    let authorId: Admin.Id
    let name: String
    let description: String?
    let isPublic: Bool
    let numKeys: Int
  }

  typealias Input = User.Id

  struct Output: TypescriptPairOutput {
    var id: User.Id
    var name: String
    var keyloggingEnabled: Bool
    var screenshotsEnabled: Bool
    var screenshotsResolution: Int
    var screenshotsFrequency: Int
    var keychains: [Keychain]
    var devices: [Device]
    var createdAt: Date
  }
}

// resolver

extension GetUser: Resolver {
  static func resolve(
    with id: User.Id,
    in context: AdminContext
  ) async throws -> Output {
    try await Output(from: context.verifiedUser(from: id))
  }
}

extension GetUser.Keychain {
  init(from keychain: App.Keychain) async throws {
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

extension GetUser.Output {
  init(from user: User) async throws {
    async let userKeychains = user.keychains()
      .concurrentMap { try await GetUser.Keychain(from: $0) }

    async let devices = Current.db.query(Device.self)
      .where(.userId == user.id)
      .all()
      .map { device in
        GetUser.Device(
          id: device.id,
          isOnline: device.isOnline,
          modelFamily: device.model.family,
          modelTitle: device.model.shortDescription
        )
      }

    self.init(
      id: user.id,
      name: user.name,
      keyloggingEnabled: user.keyloggingEnabled,
      screenshotsEnabled: user.screenshotsEnabled,
      screenshotsResolution: user.screenshotsResolution,
      screenshotsFrequency: user.screenshotsFrequency,
      keychains: try await userKeychains,
      devices: try await devices,
      createdAt: user.createdAt
    )
  }
}
