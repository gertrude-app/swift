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

  private struct _CaseFiltertextupdated: Codable {
    var `case` = "filterTextUpdated"
    var text: String
  }

  private struct _CaseUnlockrequestsubmitted: Codable {
    var `case` = "unlockRequestSubmitted"
    var comment: String?
  }

  private struct _CaseTogglerequestselected: Codable {
    var `case` = "toggleRequestSelected"
    var id: UUID
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .filterTextUpdated(let text):
      try _CaseFiltertextupdated(text: text).encode(to: encoder)
    case .unlockRequestSubmitted(let comment):
      try _CaseUnlockrequestsubmitted(comment: comment).encode(to: encoder)
    case .toggleRequestSelected(let id):
      try _CaseTogglerequestselected(id: id).encode(to: encoder)
    case .requestFailedTryAgainClicked:
      try _NamedCase(case: "requestFailedTryAgainClicked").encode(to: encoder)
    case .tcpOnlyToggled:
      try _NamedCase(case: "tcpOnlyToggled").encode(to: encoder)
    case .clearRequestsClicked:
      try _NamedCase(case: "clearRequestsClicked").encode(to: encoder)
    case .closeWindow:
      try _NamedCase(case: "closeWindow").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "filterTextUpdated":
      let value = try container.decode(_CaseFiltertextupdated.self)
      self = .filterTextUpdated(text: value.text)
    case "unlockRequestSubmitted":
      let value = try container.decode(_CaseUnlockrequestsubmitted.self)
      self = .unlockRequestSubmitted(comment: value.comment)
    case "toggleRequestSelected":
      let value = try container.decode(_CaseTogglerequestselected.self)
      self = .toggleRequestSelected(id: value.id)
    case "requestFailedTryAgainClicked":
      self = .requestFailedTryAgainClicked
    case "tcpOnlyToggled":
      self = .tcpOnlyToggled
    case "clearRequestsClicked":
      self = .clearRequestsClicked
    case "closeWindow":
      self = .closeWindow
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}