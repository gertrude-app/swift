import Foundation

public enum JSON {
  enum Error: Swift.Error {
    case dataToStringConversionError
    case stringToDataConversionError
  }

  public struct EncodeOptions: OptionSet {
    public let rawValue: Int
    public static let isoDates = EncodeOptions(rawValue: 1 << 0)
    public static let prettyPrinted = EncodeOptions(rawValue: 2 << 0)

    public init(rawValue: Int) {
      self.rawValue = rawValue
    }
  }

  public static func decode<T: Decodable>(_ json: String, as type: T.Type) throws -> T {
    let decoder = JSONDecoder()
    guard let data = json.data(using: .utf8) else {
      throw Error.stringToDataConversionError
    }
    return try decoder.decode(type, from: data)
  }

  public static func decode<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
    let decoder = JSONDecoder()
    return try decoder.decode(type, from: data)
  }

  public static func encode<T: Encodable>(
    _ value: T,
    _ options: EncodeOptions = []
  ) throws -> String {
    let data = try data(value, options)
    guard let json = String(data: data, encoding: .utf8) else {
      throw Error.dataToStringConversionError
    }
    return json
  }

  public static func data<T: Encodable>(
    _ value: T,
    _ options: EncodeOptions = []
  ) throws -> Data {
    let encoder = JSONEncoder()
    if options.contains(.isoDates) {
      encoder.dateEncodingStrategy = .iso8601
    }
    if options.contains(.prettyPrinted) {
      encoder.outputFormatting = .prettyPrinted
    }
    return try encoder.encode(value)
  }
}
