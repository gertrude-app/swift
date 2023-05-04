import Foundation

enum Failable<T> {
  case ok(value: T)
  case error(message: String?)

  static var error: Self {
    .error(message: nil)
  }

  var value: T? {
    guard case .ok(let value) = self else {
      return nil
    }
    return value
  }

  init(throwing: () async throws -> T) async {
    do {
      self = .ok(value: try await throwing())
    } catch {
      self = .error
    }
  }
}

extension Failable: Equatable where T: Equatable {}
extension Failable: Sendable where T: Sendable {}

extension Failable: Codable where T: Codable {
  private struct _NamedCase: Codable {
    var `case`: String
    static func extract(from decoder: Decoder) throws -> String {
      let container = try decoder.singleValueContainer()
      return try container.decode(_NamedCase.self).case
    }
  }

  private struct _TypeScriptDecodeError: Error {
    var message: String
  }

  private struct _CaseOk: Codable {
    var `case` = "ok"
    var value: T
  }

  private struct _CaseError: Codable {
    var `case` = "error"
    var message: String?
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .ok(let value):
      try _CaseOk(value: value).encode(to: encoder)
    case .error(let message):
      try _CaseError(message: message).encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "ok":
      let value = try container.decode(_CaseOk.self)
      self = .ok(value: value.value)
    case "error":
      let value = try container.decode(_CaseError.self)
      self = .error(message: value.message)
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}
