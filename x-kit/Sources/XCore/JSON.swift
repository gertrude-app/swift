public enum JSON {
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

  public static func encode<T: Encodable>(_ value: T) throws -> String {
    let encoder = JSONEncoder()
    let data = try encoder.encode(value)
    guard let json = String(data: data, encoding: .utf8) else {
      throw Error.dataToStringConversionError
    }
    return json
  }
}

// extensions

public extension Encodable {
  var json: String? {
    try? JSON.encode(self)
  }

  var jsonData: Data? {
    try? JSONEncoder().encode(self)
  }
}

extension JSON {
  enum Error: Swift.Error {
    case dataToStringConversionError
    case stringToDataConversionError
  }
}
