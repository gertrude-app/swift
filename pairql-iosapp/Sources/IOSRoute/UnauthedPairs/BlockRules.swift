import Foundation
import GertieIOS
import PairQL

/// deprecated: v1.0.0 - v1.1.x
public struct BlockRules: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var vendorId: UUID?
    public var version: String?

    public init(vendorId: UUID? = nil, version: String? = nil) {
      self.vendorId = vendorId
      self.version = version
    }
  }

  public typealias Output = [BlockRule]
}

extension BlockRule: @retroactive PairOutput {}
