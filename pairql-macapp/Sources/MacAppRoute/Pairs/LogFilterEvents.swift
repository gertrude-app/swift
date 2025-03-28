import Foundation
import Gertie
import PairQL

/// in use: v2.5.0 - present
public struct LogFilterEvents: Pair {
  public static let auth: ClientAuth = .child
  public typealias Input = FilterLogs
  public typealias Output = Infallible
}

extension FilterLogs: @retroactive PairInput {}
