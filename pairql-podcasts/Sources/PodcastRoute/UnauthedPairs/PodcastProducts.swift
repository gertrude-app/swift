import Foundation
import PairQL

/// in use: v1.0.0 - present
public struct PodcastProducts: Pair {
  public static let auth: ClientAuth = .none

  public typealias Input = NoInput
  public typealias Output = [String]
}
