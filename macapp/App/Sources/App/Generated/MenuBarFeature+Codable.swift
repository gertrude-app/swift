// auto-generated, do not edit
import Foundation

extension FilterState {
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
    var resuming: String
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .suspended(let resuming):
      try _CaseSuspended(resuming: resuming).encode(to: encoder)
    case .off:
      try _NamedCase(case: "off").encode(to: encoder)
    case .on:
      try _NamedCase(case: "on").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "suspended":
      let value = try container.decode(_CaseSuspended.self)
      self = .suspended(resuming: value.resuming)
    case "off":
      self = .off
    case "on":
      self = .on
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

extension MenuBarFeature.Action {
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

  private struct _CaseConnectSubmit: Codable {
    var `case` = "connectSubmit"
    var code: Int
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .connectSubmit(let code):
      try _CaseConnectSubmit(code: code).encode(to: encoder)
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
    case .retryConnectClicked:
      try _NamedCase(case: "retryConnectClicked").encode(to: encoder)
    case .connectFailedHelpClicked:
      try _NamedCase(case: "connectFailedHelpClicked").encode(to: encoder)
    case .welcomeAdminClicked:
      try _NamedCase(case: "welcomeAdminClicked").encode(to: encoder)
    case .turnOnFilterClicked:
      try _NamedCase(case: "turnOnFilterClicked").encode(to: encoder)
    case .updateNagDismissClicked:
      try _NamedCase(case: "updateNagDismissClicked").encode(to: encoder)
    case .updateNagUpdateClicked:
      try _NamedCase(case: "updateNagUpdateClicked").encode(to: encoder)
    case .updateRequiredUpdateClicked:
      try _NamedCase(case: "updateRequiredUpdateClicked").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "connectSubmit":
      let value = try container.decode(_CaseConnectSubmit.self)
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
    case "retryConnectClicked":
      self = .retryConnectClicked
    case "connectFailedHelpClicked":
      self = .connectFailedHelpClicked
    case "welcomeAdminClicked":
      self = .welcomeAdminClicked
    case "turnOnFilterClicked":
      self = .turnOnFilterClicked
    case "updateNagDismissClicked":
      self = .updateNagDismissClicked
    case "updateNagUpdateClicked":
      self = .updateNagUpdateClicked
    case "updateRequiredUpdateClicked":
      self = .updateRequiredUpdateClicked
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

extension MenuBarFeature.State.View {
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

  private struct _CaseConnectionFailed: Codable {
    var `case` = "connectionFailed"
    var error: String
  }

  private struct _CaseConnectionSucceded: Codable {
    var `case` = "connectionSucceded"
    var userName: String
  }

  private struct _CaseConnected: Codable {
    var `case` = "connected"
    var filterState: FilterState
    var recordingScreen: Bool
    var recordingKeystrokes: Bool
    var adminAttentionRequired: Bool
    var updateStatus: MenuBarFeature.State.View.Connected.UpdateStatus?
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .connectionFailed(let error):
      try _CaseConnectionFailed(error: error).encode(to: encoder)
    case .connectionSucceded(let userName):
      try _CaseConnectionSucceded(userName: userName).encode(to: encoder)
    case .connected(let unflat):
      try _CaseConnected(
        filterState: unflat.filterState,
        recordingScreen: unflat.recordingScreen,
        recordingKeystrokes: unflat.recordingKeystrokes,
        adminAttentionRequired: unflat.adminAttentionRequired,
        updateStatus: unflat.updateStatus
      ).encode(to: encoder)
    case .notConnected:
      try _NamedCase(case: "notConnected").encode(to: encoder)
    case .enteringConnectionCode:
      try _NamedCase(case: "enteringConnectionCode").encode(to: encoder)
    case .connecting:
      try _NamedCase(case: "connecting").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "connectionFailed":
      let value = try container.decode(_CaseConnectionFailed.self)
      self = .connectionFailed(error: value.error)
    case "connectionSucceded":
      let value = try container.decode(_CaseConnectionSucceded.self)
      self = .connectionSucceded(userName: value.userName)
    case "connected":
      let value = try container.decode(_CaseConnected.self)
      self = .connected(.init(
        filterState: value.filterState,
        recordingScreen: value.recordingScreen,
        recordingKeystrokes: value.recordingKeystrokes,
        adminAttentionRequired: value.adminAttentionRequired,
        updateStatus: value.updateStatus
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
