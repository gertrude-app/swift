// auto-generated, do not edit

extension MenuBar.Action: Codable {
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

  private struct _CaseConnectsubmit: Codable {
    var `case` = "connectSubmit"
    var code: Int
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .connectSubmit(let code):
      try _CaseConnectsubmit(code: code).encode(to: encoder)
    case .menuBarIconClicked:
      try _NamedCase(case: "menuBarIconClicked").encode(to: encoder)
    case .resumeFilterClicked:
      try _NamedCase(case: "resumeFilterClicked").encode(to: encoder)
    case .suspendFilterClicked:
      try _NamedCase(case: "suspendFilterClicked").encode(to: encoder)
    case .refreshRulesClicked:
      try _NamedCase(case: "refreshRulesClicked").encode(to: encoder)
    case .administrateClicked:
      try _NamedCase(case: "administrateClicked").encode(to: encoder)
    case .viewNetworkTrafficClicked:
      try _NamedCase(case: "viewNetworkTrafficClicked").encode(to: encoder)
    case .connectClicked:
      try _NamedCase(case: "connectClicked").encode(to: encoder)
    }
  }

  public init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "connectSubmit":
      let value = try container.decode(_CaseConnectsubmit.self)
      self = .connectSubmit(code: value.code)
    case "menuBarIconClicked":
      self = .menuBarIconClicked
    case "resumeFilterClicked":
      self = .resumeFilterClicked
    case "suspendFilterClicked":
      self = .suspendFilterClicked
    case "refreshRulesClicked":
      self = .refreshRulesClicked
    case "administrateClicked":
      self = .administrateClicked
    case "viewNetworkTrafficClicked":
      self = .viewNetworkTrafficClicked
    case "connectClicked":
      self = .connectClicked
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

extension MenuBar.State.FilterState: Codable {
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

extension Connection.State: Codable {
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

  private struct _CaseConnectfailed: Codable {
    var `case` = "connectFailed"
    var connectFailed: String
  }

  private struct _CaseConnected: Codable {
    var `case` = "connected"
    var name: String
    var keyloggingEnabled: Bool
    var screenshotsEnabled: Bool
    var screenshotFrequency: Int
    var screenshotSize: Int
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .connectFailed(let connectFailed):
      try _CaseConnectfailed(connectFailed: connectFailed).encode(to: encoder)
    case .connected(let unflat):
      try _CaseConnected(
        name: unflat.name,
        keyloggingEnabled: unflat.keyloggingEnabled,
        screenshotsEnabled: unflat.screenshotsEnabled,
        screenshotFrequency: unflat.screenshotFrequency,
        screenshotSize: unflat.screenshotSize
      ).encode(to: encoder)
    case .notConnected:
      try _NamedCase(case: "notConnected").encode(to: encoder)
    case .enteringConnectionCode:
      try _NamedCase(case: "enteringConnectionCode").encode(to: encoder)
    case .connecting:
      try _NamedCase(case: "connecting").encode(to: encoder)
    }
  }

  public init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "connectFailed":
      let value = try container.decode(_CaseConnectfailed.self)
      self = .connectFailed(value.connectFailed)
    case "connected":
      let value = try container.decode(_CaseConnected.self)
      self = .connected(.init(
        name: value.name,
        keyloggingEnabled: value.keyloggingEnabled,
        screenshotsEnabled: value.screenshotsEnabled,
        screenshotFrequency: value.screenshotFrequency,
        screenshotSize: value.screenshotSize
      ))
    case "notConnected":
      self = .notConnected
    case "enteringConnectionCode":
      self = .enteringConnectionCode
    case "connecting":
      self = .connecting
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}
