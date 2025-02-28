import Foundation
import GertieIOS
import PairQL

public struct BlockRules_v2: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var disabledGroups: [BlockGroup]
    public var vendorId: UUID
    public var version: String

    public init(disabledGroups: [BlockGroup], vendorId: UUID, version: String) {
      self.disabledGroups = disabledGroups
      self.vendorId = vendorId
      self.version = version
    }
  }

  public typealias Output = [BlockRule]
}

extension BlockRules_v2: PairOutput {}
