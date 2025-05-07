import Foundation
import PairQL

/// in use: v2.0.0 - present
public struct CreateKeystrokeLines: Pair {
  public static let auth: ClientAuth = .child

  public typealias Input = [KeystrokeLineInput]

  public struct KeystrokeLineInput: PairInput, Sendable {
    public var appName: String
    public var line: String
    public var filterSuspended: Bool?
    public var time: Date

    public init(appName: String, line: String, filterSuspended: Bool?, time: Date) {
      self.appName = appName
      self.line = line
      self.filterSuspended = filterSuspended
      self.time = time
    }
  }
}
