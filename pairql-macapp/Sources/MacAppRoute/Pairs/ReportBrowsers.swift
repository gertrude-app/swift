import Foundation
import PairQL

/// in use: v2.2.0 - present
public struct ReportBrowsers: Pair {
  public static var auth: ClientAuth = .user

  public struct BrowserInput: PairInput {
    public var name: String
    public var bundleId: String
  }

  public typealias Input = [BrowserInput]
}
