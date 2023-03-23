import Dependencies
import Foundation
import XCore

protocol JsonClient: Sendable {
  func decode<T: Decodable>(_ json: String, as type: T.Type) throws -> T
  func encode<T: Encodable>(_ value: T) throws -> String
}

struct JsonLiveClient: JsonClient {
  func decode<T: Decodable>(_ json: String, as type: T.Type) throws -> T {
    try JSON.decode(json, as: type)
  }

  func encode<T: Encodable>(_ value: T) throws -> String {
    try JSON.encode(value)
  }
}

struct JsonUnimplementedClient: JsonClient {
  struct UnimplementedError: Error {}
  func decode<T: Decodable>(_ json: String, as type: T.Type) throws -> T {
    XCTFail("JsonUnimplementedClient.decode() called")
    throw UnimplementedError()
  }

  func encode<T: Encodable>(_ value: T) throws -> String {
    XCTFail("JsonUnimplementedClient.encode() called")
    throw UnimplementedError()
  }
}

enum JsonClientKey: DependencyKey {
  static let liveValue: any JsonClient = JsonLiveClient()
}

extension JsonClientKey: TestDependencyKey {
  static let testValue: any JsonClient = JsonLiveClient()
}

extension DependencyValues {
  var json: JsonClient {
    get { self[JsonClientKey.self] }
    set { self[JsonClientKey.self] = newValue }
  }
}
