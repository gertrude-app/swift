import Foundation

public struct Base64EncodedString: Codable, Equatable, Hashable {
  public let encoded: String
  public let decoded: String

  public init(data: Data) throws {
    try self.init(encoded: data.base64EncodedString())
  }

  public init(encoded: String) throws {
    guard let decoded = decode(encoded) else {
      throw Error.notDecodable(encoded)
    }
    self.encoded = encoded
    self.decoded = decoded
  }

  public init(unencoded: String) throws {
    guard let encoded = unencoded.data(using: .utf8)?.base64EncodedString() else {
      throw Error.notEncodable(unencoded)
    }
    guard let decoded = decode(encoded) else {
      throw Error.notDecodable(encoded)
    }
    self.encoded = encoded
    self.decoded = decoded
  }
}

// extensions

public extension Base64EncodedString {
  enum Error: Swift.Error, LocalizedError {
    case notDecodable(String)
    case notEncodable(String)

    public var errorDescription: String? {
      switch self {
      case .notDecodable(let string):
        "String `\(string)` not base-64 decodable"
      case .notEncodable(let string):
        "String `\(string)` not base-64 encodable"
      }
    }
  }
}

// helpers

private func decode(_ encoded: String) -> String? {
  guard let data = Data(base64Encoded: encoded) else { return nil }
  return String(data: data, encoding: .utf8)
}
