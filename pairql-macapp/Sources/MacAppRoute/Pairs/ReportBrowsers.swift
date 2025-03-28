import Foundation
import PairQL

/// in use: v2.2.0 - present
public struct ReportBrowsers: Pair {
  public static let auth: ClientAuth = .child

  public struct BrowserInput: PairInput {
    public var name: String
    public var bundleId: String

    public init(name: String, bundleId: String) {
      self.name = name
      self.bundleId = bundleId
    }
  }

  public typealias Input = [BrowserInput]
}
