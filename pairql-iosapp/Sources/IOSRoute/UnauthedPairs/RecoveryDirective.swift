import Foundation
import GertieIOS
import PairQL

/// in use: v1.3.1 - present
public struct RecoveryDirective: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var vendorId: UUID?
    public var deviceType: String
    public var iOSVersion: String
    public var locale: String?
    public var version: String?

    public init(
      vendorId: UUID?,
      deviceType: String,
      iOSVersion: String,
      locale: String? = nil,
      version: String? = nil,
    ) {
      self.vendorId = vendorId
      self.deviceType = deviceType
      self.iOSVersion = iOSVersion
      self.locale = locale
      self.version = version
    }
  }

  public struct Output: PairOutput {
    public var directive: String?

    public init(directive: String?) {
      self.directive = directive
    }
  }
}
