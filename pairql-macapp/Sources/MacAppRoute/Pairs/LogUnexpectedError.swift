import Foundation
import PairQL

public struct LogUnexpectedError: Pair {
  public static var auth: ClientAuth = .none

  public struct Input: PairInput {
    public var errorId: String
    public var deviceId: UUID?
    public var detail: String?

    public init(errorId: String, deviceId: UUID? = nil, detail: String? = nil) {
      self.errorId = errorId
      self.deviceId = deviceId
      self.detail = detail
    }
  }
}
