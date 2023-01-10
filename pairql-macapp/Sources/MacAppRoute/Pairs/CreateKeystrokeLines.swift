import Foundation
import PairQL

public struct CreateKeystrokeLines: Pair {
  public static var auth: ClientAuth = .user

  public typealias Input = [KeystrokeLineInput]

  public struct KeystrokeLineInput: PairInput {
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
