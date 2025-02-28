import Foundation
import GertieIOS
import PairQL

/// in use: v1.3.0 - present
public struct DefaultBlockRules: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var vendorId: UUID?
    public var version: String

    public init(vendorId: UUID?, version: String) {
      self.vendorId = vendorId
      self.version = version
    }
  }

  public typealias Output = [BlockRule]
}

extension DefaultBlockRules: PairOutput {}
