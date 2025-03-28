import Foundation

enum RequestState<E> {
  case idle
  case ongoing
  case succeeded
  case failed(error: E)
}

enum PayloadRequestState<T, E> {
  case idle
  case ongoing
  case succeeded(payload: T)
  case failed(error: E)

  var isSucceeded: Bool {
    switch self {
    case .succeeded:
      true
    default:
      false
    }
  }

  var isFailed: Bool {
    switch self {
    case .failed:
      true
    default:
      false
    }
  }
}

extension RequestState: Equatable where E: Equatable {}
extension RequestState: Sendable where E: Sendable {}
extension PayloadRequestState: Equatable where T: Equatable, E: Equatable {}
extension PayloadRequestState: Sendable where T: Sendable, E: Sendable {}

extension RequestState: Codable where E: Codable {
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

  private struct _CaseFailed: Codable {
    var `case` = "failed"
    var error: E
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .failed(let error):
      try _CaseFailed(error: error).encode(to: encoder)
    case .idle:
      try _NamedCase(case: "idle").encode(to: encoder)
    case .ongoing:
      try _NamedCase(case: "ongoing").encode(to: encoder)
    case .succeeded:
      try _NamedCase(case: "succeeded").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "failed":
      let value = try container.decode(_CaseFailed.self)
      self = .failed(error: value.error)
    case "idle":
      self = .idle
    case "ongoing":
      self = .ongoing
    case "succeeded":
      self = .succeeded
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

extension PayloadRequestState: Codable where T: Codable, E: Codable {
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

  private struct _CaseSucceeded: Codable {
    var `case` = "succeeded"
    var payload: T
  }

  private struct _CaseFailed: Codable {
    var `case` = "failed"
    var error: E
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .succeeded(let payload):
      try _CaseSucceeded(payload: payload).encode(to: encoder)
    case .failed(let error):
      try _CaseFailed(error: error).encode(to: encoder)
    case .idle:
      try _NamedCase(case: "idle").encode(to: encoder)
    case .ongoing:
      try _NamedCase(case: "ongoing").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "succeeded":
      let value = try container.decode(_CaseSucceeded.self)
      self = .succeeded(payload: value.payload)
    case "failed":
      let value = try container.decode(_CaseFailed.self)
      self = .failed(error: value.error)
    case "idle":
      self = .idle
    case "ongoing":
      self = .ongoing
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}
