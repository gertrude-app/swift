// auto-generated, do not edit
import Foundation

extension RequestSuspensionFeature.Action.View {
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

  private struct _CaseRequestSubmitted: Codable {
    var `case` = "requestSubmitted"
    var durationInSeconds: Int
    var comment: String?
  }

  private struct _CaseGrantSuspensionClicked: Codable {
    var `case` = "grantSuspensionClicked"
    var durationInSeconds: Int
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .requestSubmitted(let durationInSeconds, let comment):
      try _CaseRequestSubmitted(durationInSeconds: durationInSeconds, comment: comment)
        .encode(to: encoder)
    case .grantSuspensionClicked(let durationInSeconds):
      try _CaseGrantSuspensionClicked(durationInSeconds: durationInSeconds).encode(to: encoder)
    case .closeWindow:
      try _NamedCase(case: "closeWindow").encode(to: encoder)
    case .requestFailedTryAgainClicked:
      try _NamedCase(case: "requestFailedTryAgainClicked").encode(to: encoder)
    case .inactiveAccountRecheckClicked:
      try _NamedCase(case: "inactiveAccountRecheckClicked").encode(to: encoder)
    case .inactiveAccountDisconnectAppClicked:
      try _NamedCase(case: "inactiveAccountDisconnectAppClicked").encode(to: encoder)
    case .noFilterCommunicationAdministrateClicked:
      try _NamedCase(case: "noFilterCommunicationAdministrateClicked").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "requestSubmitted":
      let value = try container.decode(_CaseRequestSubmitted.self)
      self = .requestSubmitted(durationInSeconds: value.durationInSeconds, comment: value.comment)
    case "grantSuspensionClicked":
      let value = try container.decode(_CaseGrantSuspensionClicked.self)
      self = .grantSuspensionClicked(durationInSeconds: value.durationInSeconds)
    case "closeWindow":
      self = .closeWindow
    case "requestFailedTryAgainClicked":
      self = .requestFailedTryAgainClicked
    case "inactiveAccountRecheckClicked":
      self = .inactiveAccountRecheckClicked
    case "inactiveAccountDisconnectAppClicked":
      self = .inactiveAccountDisconnectAppClicked
    case "noFilterCommunicationAdministrateClicked":
      self = .noFilterCommunicationAdministrateClicked
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}
