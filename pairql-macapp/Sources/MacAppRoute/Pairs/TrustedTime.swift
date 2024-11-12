import Foundation
import PairQL

/// in use: v2.5.0 - present
public struct TrustedTime: Pair {
  public static let auth: ClientAuth = .none
  public typealias Output = Double
}
