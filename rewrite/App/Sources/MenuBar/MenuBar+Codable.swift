// auto-generated, do not edit

extension MenuBar.State.Connected.FilterState: Codable {
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

  private struct _CaseSuspended: Codable {
    var `case` = "suspended"
    var expiration: String
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .suspended(let expiration):
      try _CaseSuspended(expiration: expiration).encode(to: encoder)
    case .off:
      try _NamedCase(case: "off").encode(to: encoder)
    case .on:
      try _NamedCase(case: "on").encode(to: encoder)
    }
  }

  public init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "suspended":
      let value = try container.decode(_CaseSuspended.self)
      self = .suspended(expiration: value.expiration)
    case "off":
      self = .off
    case "on":
      self = .on
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

extension MenuBar.State.Screen: Codable {
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

  private struct _CaseConnected: Codable {
    var `case` = "connected"
    var recordingKeystrokes: Bool
    var recordingScreen: Bool
    var filterState: MenuBar.State.Connected.FilterState
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .connected(let unflat):
      try _CaseConnected(
        recordingKeystrokes: unflat.recordingKeystrokes,
        recordingScreen: unflat.recordingScreen,
        filterState: unflat.filterState
      ).encode(to: encoder)
    case .notConnected:
      try _NamedCase(case: "notConnected").encode(to: encoder)
    }
  }

  public init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "connected":
      let value = try container.decode(_CaseConnected.self)
      self = .connected(.init(
        recordingKeystrokes: value.recordingKeystrokes,
        recordingScreen: value.recordingScreen,
        filterState: value.filterState
      ))
    case "notConnected":
      self = .notConnected
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}
