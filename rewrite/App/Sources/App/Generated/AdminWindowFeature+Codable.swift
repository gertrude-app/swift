// auto-generated, do not edit
import Foundation

extension AdminWindowFeature.State.HealthCheck.FilterStatus {
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

  private struct _CaseInstalled: Codable {
    var `case` = "installed"
    var version: String
    var numUserKeys: Int
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .installed(let version, let numUserKeys):
      try _CaseInstalled(version: version, numUserKeys: numUserKeys).encode(to: encoder)
    case .installing:
      try _NamedCase(case: "installing").encode(to: encoder)
    case .installTimeout:
      try _NamedCase(case: "installTimeout").encode(to: encoder)
    case .notInstalled:
      try _NamedCase(case: "notInstalled").encode(to: encoder)
    case .unexpected:
      try _NamedCase(case: "unexpected").encode(to: encoder)
    case .communicationBroken:
      try _NamedCase(case: "communicationBroken").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "installed":
      let value = try container.decode(_CaseInstalled.self)
      self = .installed(version: value.version, numUserKeys: value.numUserKeys)
    case "installing":
      self = .installing
    case "installTimeout":
      self = .installTimeout
    case "notInstalled":
      self = .notInstalled
    case "unexpected":
      self = .unexpected
    case "communicationBroken":
      self = .communicationBroken
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

extension AdminWindowFeature.Action.View {
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

  private struct _CaseHealthcheck: Codable {
    var `case` = "healthCheck"
    var action: AdminWindowFeature.Action.View.HealthCheckAction
  }

  private struct _CaseGotoscreenclicked: Codable {
    var `case` = "gotoScreenClicked"
    var screen: AdminWindowFeature.Screen
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .healthCheck(let action):
      try _CaseHealthcheck(action: action).encode(to: encoder)
    case .gotoScreenClicked(let screen):
      try _CaseGotoscreenclicked(screen: screen).encode(to: encoder)
    case .closeWindow:
      try _NamedCase(case: "closeWindow").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "healthCheck":
      let value = try container.decode(_CaseHealthcheck.self)
      self = .healthCheck(action: value.action)
    case "gotoScreenClicked":
      let value = try container.decode(_CaseGotoscreenclicked.self)
      self = .gotoScreenClicked(screen: value.screen)
    case "closeWindow":
      self = .closeWindow
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}
