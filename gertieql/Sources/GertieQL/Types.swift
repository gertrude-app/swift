import Foundation

public protocol Pair {
  associatedtype Input: Codable & Equatable = NoInput
  associatedtype Output: PairOutput = SuccessOutput
}

public protocol PairOutput: Codable, Equatable {
  func jsonData() throws -> Data
}

public enum ClientAuth: String, TsType {
  public static var ts: String {
    """
    export enum ClientAuth {
      none,
      user,
      admin,
    }
    """
  }

  case none
  case user
  case admin
}

public struct GertieQLJsonEncodingError: Error {}

public extension PairOutput {
  func jsonData() throws -> Data {
    try JSONEncoder().encode(self)
  }

  func json() throws -> String {
    guard let json = String(data: try jsonData(), encoding: .utf8) else {
      throw GertieQLJsonEncodingError()
    }
    return json
  }
}

public struct NoInput: TsPairInput {
  public static var ts: String { "type __self___ = never;" }

  public init() {}
}

public struct SuccessOutput: TsPairOutput {
  public let success: Bool

  public static var ts: String {
    """
    interface __self__ {
      success: boolean;
    }
    """
  }

  public init(_ success: Bool) {
    self.success = success
  }
}
