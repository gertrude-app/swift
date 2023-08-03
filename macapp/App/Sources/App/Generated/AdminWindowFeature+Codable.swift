// auto-generated, do not edit
import Foundation
import Gertie

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

  private struct _CaseCommunicationBroken: Codable {
    var `case` = "communicationBroken"
    var repairing: Bool
  }

  private struct _CaseInstalled: Codable {
    var `case` = "installed"
    var version: String
    var numUserKeys: Int
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .communicationBroken(let repairing):
      try _CaseCommunicationBroken(repairing: repairing).encode(to: encoder)
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
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "communicationBroken":
      let value = try container.decode(_CaseCommunicationBroken.self)
      self = .communicationBroken(repairing: value.repairing)
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
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

extension AdminWindowFeature.Action.View.AdvancedAction {
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

  private struct _CasePairqlEndpointSet: Codable {
    var `case` = "pairqlEndpointSet"
    var url: String?
  }

  private struct _CaseWebsocketEndpointSet: Codable {
    var `case` = "websocketEndpointSet"
    var url: String?
  }

  private struct _CaseAppcastEndpointSet: Codable {
    var `case` = "appcastEndpointSet"
    var url: String?
  }

  private struct _CaseForceUpdateToSpecificVersionClicked: Codable {
    var `case` = "forceUpdateToSpecificVersionClicked"
    var version: String
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .pairqlEndpointSet(let url):
      try _CasePairqlEndpointSet(url: url).encode(to: encoder)
    case .websocketEndpointSet(let url):
      try _CaseWebsocketEndpointSet(url: url).encode(to: encoder)
    case .appcastEndpointSet(let url):
      try _CaseAppcastEndpointSet(url: url).encode(to: encoder)
    case .forceUpdateToSpecificVersionClicked(let version):
      try _CaseForceUpdateToSpecificVersionClicked(version: version).encode(to: encoder)
    case .deleteAllDeviceStorageClicked:
      try _NamedCase(case: "deleteAllDeviceStorageClicked").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "pairqlEndpointSet":
      let value = try container.decode(_CasePairqlEndpointSet.self)
      self = .pairqlEndpointSet(url: value.url)
    case "websocketEndpointSet":
      let value = try container.decode(_CaseWebsocketEndpointSet.self)
      self = .websocketEndpointSet(url: value.url)
    case "appcastEndpointSet":
      let value = try container.decode(_CaseAppcastEndpointSet.self)
      self = .appcastEndpointSet(url: value.url)
    case "forceUpdateToSpecificVersionClicked":
      let value = try container.decode(_CaseForceUpdateToSpecificVersionClicked.self)
      self = .forceUpdateToSpecificVersionClicked(version: value.version)
    case "deleteAllDeviceStorageClicked":
      self = .deleteAllDeviceStorageClicked
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

  private struct _CaseHealthCheck: Codable {
    var `case` = "healthCheck"
    var action: AdminWindowFeature.Action.View.HealthCheckAction
  }

  private struct _CaseAdvanced: Codable {
    var `case` = "advanced"
    var action: AdminWindowFeature.Action.View.AdvancedAction
  }

  private struct _CaseGotoScreenClicked: Codable {
    var `case` = "gotoScreenClicked"
    var screen: AdminWindowFeature.Screen
  }

  private struct _CaseReleaseChannelUpdated: Codable {
    var `case` = "releaseChannelUpdated"
    var channel: ReleaseChannel
  }

  private struct _CaseSetUserExemption: Codable {
    var `case` = "setUserExemption"
    var userId: UInt32
    var enabled: Bool
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .healthCheck(let action):
      try _CaseHealthCheck(action: action).encode(to: encoder)
    case .advanced(let action):
      try _CaseAdvanced(action: action).encode(to: encoder)
    case .gotoScreenClicked(let screen):
      try _CaseGotoScreenClicked(screen: screen).encode(to: encoder)
    case .releaseChannelUpdated(let channel):
      try _CaseReleaseChannelUpdated(channel: channel).encode(to: encoder)
    case .setUserExemption(let userId, let enabled):
      try _CaseSetUserExemption(userId: userId, enabled: enabled).encode(to: encoder)
    case .closeWindow:
      try _NamedCase(case: "closeWindow").encode(to: encoder)
    case .stopFilterClicked:
      try _NamedCase(case: "stopFilterClicked").encode(to: encoder)
    case .startFilterClicked:
      try _NamedCase(case: "startFilterClicked").encode(to: encoder)
    case .resumeFilterClicked:
      try _NamedCase(case: "resumeFilterClicked").encode(to: encoder)
    case .reinstallAppClicked:
      try _NamedCase(case: "reinstallAppClicked").encode(to: encoder)
    case .quitAppClicked:
      try _NamedCase(case: "quitAppClicked").encode(to: encoder)
    case .reconnectUserClicked:
      try _NamedCase(case: "reconnectUserClicked").encode(to: encoder)
    case .administrateOSUserAccountsClicked:
      try _NamedCase(case: "administrateOSUserAccountsClicked").encode(to: encoder)
    case .checkForAppUpdatesClicked:
      try _NamedCase(case: "checkForAppUpdatesClicked").encode(to: encoder)
    case .inactiveAccountRecheckClicked:
      try _NamedCase(case: "inactiveAccountRecheckClicked").encode(to: encoder)
    case .inactiveAccountDisconnectAppClicked:
      try _NamedCase(case: "inactiveAccountDisconnectAppClicked").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "healthCheck":
      let value = try container.decode(_CaseHealthCheck.self)
      self = .healthCheck(action: value.action)
    case "advanced":
      let value = try container.decode(_CaseAdvanced.self)
      self = .advanced(action: value.action)
    case "gotoScreenClicked":
      let value = try container.decode(_CaseGotoScreenClicked.self)
      self = .gotoScreenClicked(screen: value.screen)
    case "releaseChannelUpdated":
      let value = try container.decode(_CaseReleaseChannelUpdated.self)
      self = .releaseChannelUpdated(channel: value.channel)
    case "setUserExemption":
      let value = try container.decode(_CaseSetUserExemption.self)
      self = .setUserExemption(userId: value.userId, enabled: value.enabled)
    case "closeWindow":
      self = .closeWindow
    case "stopFilterClicked":
      self = .stopFilterClicked
    case "startFilterClicked":
      self = .startFilterClicked
    case "resumeFilterClicked":
      self = .resumeFilterClicked
    case "reinstallAppClicked":
      self = .reinstallAppClicked
    case "quitAppClicked":
      self = .quitAppClicked
    case "reconnectUserClicked":
      self = .reconnectUserClicked
    case "administrateOSUserAccountsClicked":
      self = .administrateOSUserAccountsClicked
    case "checkForAppUpdatesClicked":
      self = .checkForAppUpdatesClicked
    case "inactiveAccountRecheckClicked":
      self = .inactiveAccountRecheckClicked
    case "inactiveAccountDisconnectAppClicked":
      self = .inactiveAccountDisconnectAppClicked
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}
