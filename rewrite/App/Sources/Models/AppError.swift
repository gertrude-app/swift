import Foundation

public struct AppError: Error, LocalizedError, Sendable {
  public var msg: String
  public var errorDescription: String? { msg }
  public var unexpected: Bool

  public init(_ msg: String, unexpected: Bool = false) {
    self.msg = msg
    self.unexpected = unexpected
  }
}
