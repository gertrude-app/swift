import DuetSQL
import Foundation
import Shared
import TypescriptPairQL

struct GetUser: Pair, TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Device: Equatable, Codable, TypescriptRepresentable {
    let id: UUID
    let isOnline: Bool
    let modelFamily: DeviceModelFamily
    let modelTitle: String
  }

  struct Keychain: Equatable, Codable, TypescriptRepresentable {
    let id: UUID
    let authorId: UUID
    let name: String
    let description: String?
    let isPublic: Bool
    let numKeys: Int
  }

  typealias Input = UUID

  struct Output: TypescriptPairOutput {
    var id: UUID
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
    for id: UUID,
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
      id: keychain.id.rawValue,
      authorId: keychain.authorId.rawValue,
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
          id: device.id.rawValue,
          isOnline: device.isOnline,
          modelFamily: device.model.family,
          modelTitle: device.model.shortDescription
        )
      }

    self.init(
      id: user.id.rawValue,
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
