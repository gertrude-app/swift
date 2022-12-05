import Foundation

public struct NoInput: Codable, Equatable {}

public extension GertieQL {
  struct JSONEncodingError: Error {}
}

public protocol PairOutput: Codable, Equatable {
  func jsonData() throws -> Data
}

public extension PairOutput {
  func jsonData() throws -> Data {
    try JSONEncoder().encode(self)
  }

  func json() throws -> String {
    guard let json = String(data: try jsonData(), encoding: .utf8) else {
      throw GertieQL.JSONEncodingError()
    }
    return json
  }
}

public struct SuccessOutput: PairOutput {
  public let success: Bool
  public init(_ success: Bool) {
    self.success = success
  }
}

public protocol Pair {
  associatedtype Input: Codable & Equatable = NoInput
  associatedtype Output: PairOutput = SuccessOutput
}
