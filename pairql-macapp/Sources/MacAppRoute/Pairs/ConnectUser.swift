import Foundation
import PairQL
import Gertie

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

  public typealias Output = UserData
}
