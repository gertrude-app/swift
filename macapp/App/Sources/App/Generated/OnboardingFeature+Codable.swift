// auto-generated, do not edit
import Foundation

extension OnboardingFeature.Action.View {
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

  private struct _CaseConnectChildSubmitted: Codable {
    var `case` = "connectChildSubmitted"
    var code: Int
  }

  private struct _CaseInfoModalOpened: Codable {
    var `case` = "infoModalOpened"
    var step: OnboardingFeature.State.Step
    var detail: String?
  }

  private struct _CaseSetUserExemption: Codable {
    var `case` = "setUserExemption"
    var userId: UInt32
    var enabled: Bool
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .connectChildSubmitted(let code):
      try _CaseConnectChildSubmitted(code: code).encode(to: encoder)
    case .infoModalOpened(let step, let detail):
      try _CaseInfoModalOpened(step: step, detail: detail).encode(to: encoder)
    case .setUserExemption(let userId, let enabled):
      try _CaseSetUserExemption(userId: userId, enabled: enabled).encode(to: encoder)
    case .closeWindow:
      try _NamedCase(case: "closeWindow").encode(to: encoder)
    case .primaryBtnClicked:
      try _NamedCase(case: "primaryBtnClicked").encode(to: encoder)
    case .secondaryBtnClicked:
      try _NamedCase(case: "secondaryBtnClicked").encode(to: encoder)
    case .chooseSwitchToNonAdminUserClicked:
      try _NamedCase(case: "chooseSwitchToNonAdminUserClicked").encode(to: encoder)
    case .chooseCreateNonAdminClicked:
      try _NamedCase(case: "chooseCreateNonAdminClicked").encode(to: encoder)
    case .chooseDemoteAdminClicked:
      try _NamedCase(case: "chooseDemoteAdminClicked").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "connectChildSubmitted":
      let value = try container.decode(_CaseConnectChildSubmitted.self)
      self = .connectChildSubmitted(code: value.code)
    case "infoModalOpened":
      let value = try container.decode(_CaseInfoModalOpened.self)
      self = .infoModalOpened(step: value.step, detail: value.detail)
    case "setUserExemption":
      let value = try container.decode(_CaseSetUserExemption.self)
      self = .setUserExemption(userId: value.userId, enabled: value.enabled)
    case "closeWindow":
      self = .closeWindow
    case "primaryBtnClicked":
      self = .primaryBtnClicked
    case "secondaryBtnClicked":
      self = .secondaryBtnClicked
    case "chooseSwitchToNonAdminUserClicked":
      self = .chooseSwitchToNonAdminUserClicked
    case "chooseCreateNonAdminClicked":
      self = .chooseCreateNonAdminClicked
    case "chooseDemoteAdminClicked":
      self = .chooseDemoteAdminClicked
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}
