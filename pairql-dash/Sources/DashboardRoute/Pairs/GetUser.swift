import Foundation
import Shared
import TypescriptPairQL

public struct GetUser: Pair, TypescriptPair {
  public static var auth: ClientAuth = .admin

  public typealias Input = UUID

  public struct Output: TypescriptPairOutput {
    public var id: UUID
    public var name: String
    public var keyloggingEnabled: Bool
    public var screenshotsEnabled: Bool
    public var screenshotsResolution: Int
    public var screenshotsFrequency: Int
    public var keychains: [Keychain]
    public var devices: [Device]
    public var createdAt: Date

    public init(
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

public struct GetUsers: Pair, TypescriptPair {
  public static var auth: ClientAuth = .admin
  public typealias Output = [GetUser.Output]
}

public extension GetUser {
  struct Device: Equatable, Codable, TypescriptRepresentable {
    public let id: UUID
    public let isOnline: Bool
    public let modelFamily: DeviceModelFamily
    public let modelTitle: String

    public init(
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
    public let id: UUID
    public let authorId: UUID
    public let name: String
    public let description: String?
    public let isPublic: Bool
    public let numKeys: Int

    public init(
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
