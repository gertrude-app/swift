// auto-generated, do not edit
import TypeScript

extension MenuBar.State.Connected.FilterState: Codable {
  private struct CaseSuspended: Codable {
    var `case` = "suspended"
    var expiration: String
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .suspended(let expiration):
      try CaseSuspended(expiration: expiration).encode(to: encoder)
    case .off:
      try NamedCase("off").encode(to: encoder)
    case .on:
      try NamedCase("on").encode(to: encoder)
    }
  }

  public init(from decoder: Decoder) throws {
    let caseName = try NamedCase.name(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "suspended":
      let value = try container.decode(CaseSuspended.self)
      self = .suspended(expiration: value.expiration)
    case "off":
      self = .off
    case "on":
      self = .on
    default:
      throw TypeScriptError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

extension MenuBar.State.Screen: Codable {
  private struct CaseConnected: Codable {
    var `case` = "connected"
    var recordingKeystrokes: Bool
    var recordingScreen: Bool
    var filterState: MenuBar.State.Connected.FilterState
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .connected(let unflat):
      try CaseConnected(
        recordingKeystrokes: unflat.recordingKeystrokes,
        recordingScreen: unflat.recordingScreen,
        filterState: unflat.filterState
      ).encode(to: encoder)
    case .notConnected:
      try NamedCase("notConnected").encode(to: encoder)
    }
  }

  public init(from decoder: Decoder) throws {
    let caseName = try NamedCase.name(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "connected":
      let value = try container.decode(CaseConnected.self)
      self = .connected(.init(
        recordingKeystrokes: value.recordingKeystrokes,
        recordingScreen: value.recordingScreen,
        filterState: value.filterState
      ))
    case "notConnected":
      self = .notConnected
    default:
      throw TypeScriptError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}
