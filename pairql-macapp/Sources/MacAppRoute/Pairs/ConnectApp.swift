import Foundation
import PairQL

public struct ConnectApp: Pair {
  public static var auth: ClientAuth = .none

  public struct Input: PairInput {
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
    public var userId: UUID
    public var userName: String
    public var token: UUID
    public var deviceId: UUID

    public init(
      userId: UUID,
      userName: String,
      token: UUID,
      deviceId: UUID
    ) {
      self.userId = userId
      self.userName = userName
      self.token = token
      self.deviceId = deviceId
    }
  }
}
