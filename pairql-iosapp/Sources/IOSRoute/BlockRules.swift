import Foundation
import GertieIOS
import PairQL

public struct BlockRules: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var vendorId: UUID?

    public init(vendorId: UUID?) {
      self.vendorId = vendorId
    }
  }

  public typealias Output = [BlockRule]
}

extension BlockRule: PairOutput {}
