import Foundation
import Shared
import TypescriptPairQL

struct GetUser: Pair, TypescriptPair {
  static var auth: ClientAuth = .admin

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

    init(
      id: UUID,
      name: String,
      keyloggingEnabled: Bool,
      screenshotsEnabled: Bool,
      screenshotsResolution: Int,
      screenshotsFrequency: Int,
      keychains: [Keychain],
      devices: [Device],
      createdAt: Date
    ) {
      self.id = id
      self.name = name
      self.keyloggingEnabled = keyloggingEnabled
      self.screenshotsEnabled = screenshotsEnabled
      self.screenshotsResolution = screenshotsResolution
      self.screenshotsFrequency = screenshotsFrequency
      self.keychains = keychains
      self.devices = devices
      self.createdAt = createdAt
    }
  }
}

struct GetUsers: Pair, TypescriptPair {
  static var auth: ClientAuth = .admin
  typealias Output = [GetUser.Output]
}

extension GetUser {
  struct Device: Equatable, Codable, TypescriptRepresentable {
    let id: UUID
    let isOnline: Bool
    let modelFamily: DeviceModelFamily
    let modelTitle: String

    init(
      id: UUID,
      isOnline: Bool,
      modelFamily: DeviceModelFamily,
      modelTitle: String
    ) {
      self.id = id
      self.isOnline = isOnline
      self.modelFamily = modelFamily
      self.modelTitle = modelTitle
    }
  }

  struct Keychain: Equatable, Codable, TypescriptRepresentable {
    let id: UUID
    let authorId: UUID
    let name: String
    let description: String?
    let isPublic: Bool
    let numKeys: Int

    init(
      id: UUID,
      authorId: UUID,
      name: String,
      description: String?,
      isPublic: Bool,
      numKeys: Int
    ) {
      self.id = id
      self.authorId = authorId
      self.name = name
      self.description = description
      self.isPublic = isPublic
      self.numKeys = numKeys
    }
  }
}
