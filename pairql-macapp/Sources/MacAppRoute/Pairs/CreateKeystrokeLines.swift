import Foundation
import PairQL

/// in use: v2.0.0 - present
public struct CreateKeystrokeLines: Pair {
  public static var auth: ClientAuth = .user

  public typealias Input = [KeystrokeLineInput]

  public struct KeystrokeLineInput: PairInput, Sendable {
    public var appName: String
    public var line: String
    public var time: Date

    public init(appName: String, line: String, time: Date) {
      self.appName = appName
      self.line = line
      self.time = time
    }
  }
}
