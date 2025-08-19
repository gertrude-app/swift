import Foundation
import GertieIOS
import PairQL

public struct ChildIOSDeviceData_b1: PairOutput {
  public var childId: UUID
  public var token: UUID
  public var deviceId: UUID
  public var childName: String

  public init(childId: UUID, token: UUID, deviceId: UUID, childName: String) {
    self.childId = childId
    self.token = token
    self.deviceId = deviceId
    self.childName = childName
  }
}

public struct ConnectDevice_b1: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var verificationCode: Int
    public var vendorId: UUID
    public var deviceType: String
    public var appVersion: String
    public var iosVersion: String

    public init(
      verificationCode: Int,
      vendorId: UUID,
      deviceType: String,
      appVersion: String,
      iosVersion: String
    ) {
      self.verificationCode = verificationCode
      self.vendorId = vendorId
      self.deviceType = deviceType
      self.appVersion = appVersion
      self.iosVersion = iosVersion
    }
  }

  public typealias Output = ChildIOSDeviceData_b1
}
