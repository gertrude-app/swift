import Foundation
import Shared
import TypescriptPairQL

public struct SaveUser: TypescriptPair {
  public static var auth: ClientAuth = .admin

  public struct Input: TypescriptPairInput {
    public var id: UUID
    public var adminId: UUID
    public var isNew: Bool
    public var name: String
    public var keyloggingEnabled: Bool
    public var screenshotsEnabled: Bool
    public var screenshotsResolution: Int
    public var screenshotsFrequency: Int
    public var keychainIds: [UUID]

    public init(
      id: UUID,
      adminId: UUID,
      isNew: Bool,
      name: String,
      keyloggingEnabled: Bool,
      screenshotsEnabled: Bool,
      screenshotsResolution: Int,
      screenshotsFrequency: Int,
      keychainIds: [UUID]
    ) {
      self.id = id
      self.adminId = adminId
      self.isNew = isNew
      self.name = name
      self.keyloggingEnabled = keyloggingEnabled
      self.screenshotsEnabled = screenshotsEnabled
      self.screenshotsResolution = screenshotsResolution
      self.screenshotsFrequency = screenshotsFrequency
      self.keychainIds = keychainIds
    }
  }
}
