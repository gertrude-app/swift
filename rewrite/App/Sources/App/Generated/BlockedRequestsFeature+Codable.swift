// auto-generated, do not edit
import Foundation

extension BlockedRequestsFeature.Action.View {
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

  private struct _CaseFilterTextUpdated: Codable {
    var `case` = "filterTextUpdated"
    var text: String
  }

  private struct _CaseUnlockRequestSubmitted: Codable {
    var `case` = "unlockRequestSubmitted"
    var comment: String?
  }

  private struct _CaseToggleRequestSelected: Codable {
    var `case` = "toggleRequestSelected"
    var id: UUID
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .filterTextUpdated(let text):
      try _CaseFilterTextUpdated(text: text).encode(to: encoder)
    case .unlockRequestSubmitted(let comment):
      try _CaseUnlockRequestSubmitted(comment: comment).encode(to: encoder)
    case .toggleRequestSelected(let id):
      try _CaseToggleRequestSelected(id: id).encode(to: encoder)
    case .requestFailedTryAgainClicked:
      try _NamedCase(case: "requestFailedTryAgainClicked").encode(to: encoder)
    case .tcpOnlyToggled:
      try _NamedCase(case: "tcpOnlyToggled").encode(to: encoder)
    case .clearRequestsClicked:
      try _NamedCase(case: "clearRequestsClicked").encode(to: encoder)
    case .closeWindow:
      try _NamedCase(case: "closeWindow").encode(to: encoder)
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
    case "filterTextUpdated":
      let value = try container.decode(_CaseFilterTextUpdated.self)
      self = .filterTextUpdated(text: value.text)
    case "unlockRequestSubmitted":
      let value = try container.decode(_CaseUnlockRequestSubmitted.self)
      self = .unlockRequestSubmitted(comment: value.comment)
    case "toggleRequestSelected":
      let value = try container.decode(_CaseToggleRequestSelected.self)
      self = .toggleRequestSelected(id: value.id)
    case "requestFailedTryAgainClicked":
      self = .requestFailedTryAgainClicked
    case "tcpOnlyToggled":
      self = .tcpOnlyToggled
    case "clearRequestsClicked":
      self = .clearRequestsClicked
    case "closeWindow":
      self = .closeWindow
    case "inactiveAccountRecheckClicked":
      self = .inactiveAccountRecheckClicked
    case "inactiveAccountDisconnectAppClicked":
      self = .inactiveAccountDisconnectAppClicked
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}
