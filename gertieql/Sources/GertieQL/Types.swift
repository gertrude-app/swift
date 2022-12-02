
public struct NoInput: Codable, Equatable {}

public struct SuccessOutput: Codable, Equatable {
  public let success: Bool
  public init(_ success: Bool) {
    self.success = success
  }
}

public protocol Pair {
  associatedtype Input: Codable & Equatable = NoInput
  associatedtype Output: Codable & Equatable = SuccessOutput
}
