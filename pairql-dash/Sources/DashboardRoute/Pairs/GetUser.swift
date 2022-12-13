import Foundation
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
    public var createdAt: Date

    public init(
      id: UUID,
      name: String,
      keyloggingEnabled: Bool,
      screenshotsEnabled: Bool,
      screenshotsResolution: Int,
      screenshotsFrequency: Int,
      createdAt: Date
    ) {
      self.id = id
      self.name = name
      self.keyloggingEnabled = keyloggingEnabled
      self.screenshotsEnabled = screenshotsEnabled
      self.screenshotsResolution = screenshotsResolution
      self.screenshotsFrequency = screenshotsFrequency
      self.createdAt = createdAt
    }
  }
}

public struct GetUsers: Pair, TypescriptPair {
  public static var auth: ClientAuth = .admin
  public typealias Output = [GetUser.Output]
}
