import Foundation
import PairQL

// 🚀 BETA: for rewrite, not in use yet
public struct ConnectUser: Pair {
  public static var auth: ClientAuth = .none

  public struct Input: PairInput, Sendable {
    public var verificationCode: Int
    public var appVersion: String
    public var hostname: String?
    public var modelIdentifier: String
    public var username: String
    public var fullUsername: String
    public var numericId: Int
    public var serialNumber: String

    public init(
      verificationCode: Int,
      appVersion: String,
      hostname: String?,
      modelIdentifier: String,
      username: String,
      fullUsername: String,
      numericId: Int,
      serialNumber: String
    ) {
      self.verificationCode = verificationCode
      self.appVersion = appVersion
      self.hostname = hostname
      self.modelIdentifier = modelIdentifier
      self.username = username
      self.fullUsername = fullUsername
      self.numericId = numericId
      self.serialNumber = serialNumber
    }
  }

  public struct Output: PairOutput {
    public var id: UUID
    public var token: UUID
    public var deviceId: UUID
    public var name: String
    public var keyloggingEnabled: Bool
    public var screenshotsEnabled: Bool
    public var screenshotFrequency: Int
    public var screenshotSize: Int

    public init(
      id: UUID,
      token: UUID,
      deviceId: UUID,
      name: String,
      keyloggingEnabled: Bool,
      screenshotsEnabled: Bool,
      screenshotFrequency: Int,
      screenshotSize: Int
    ) {
      self.id = id
      self.token = token
      self.deviceId = deviceId
      self.name = name
      self.keyloggingEnabled = keyloggingEnabled
      self.screenshotsEnabled = screenshotsEnabled
      self.screenshotFrequency = screenshotFrequency
      self.screenshotSize = screenshotSize
    }
  }
}
