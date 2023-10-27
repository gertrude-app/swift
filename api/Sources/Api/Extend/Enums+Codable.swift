// auto-generated, do not edit
import Foundation
import Tagged

extension AdminVerifiedNotificationMethod.Config {
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

  private struct _CaseSlack: Codable {
    var `case` = "slack"
    var channelId: String
    var channelName: String
    var token: String
  }

  private struct _CaseEmail: Codable {
    var `case` = "email"
    var email: String
  }

  private struct _CaseText: Codable {
    var `case` = "text"
    var phoneNumber: String
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .slack(let channelId, let channelName, let token):
      try _CaseSlack(channelId: channelId, channelName: channelName, token: token)
        .encode(to: encoder)
    case .email(let email):
      try _CaseEmail(email: email).encode(to: encoder)
    case .text(let phoneNumber):
      try _CaseText(phoneNumber: phoneNumber).encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "slack":
      let value = try container.decode(_CaseSlack.self)
      self = .slack(channelId: value.channelId, channelName: value.channelName, token: value.token)
    case "email":
      let value = try container.decode(_CaseEmail.self)
      self = .email(email: value.email)
    case "text":
      let value = try container.decode(_CaseText.self)
      self = .text(phoneNumber: value.phoneNumber)
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

extension DecideFilterSuspensionRequest.Decision {
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

  private struct _CaseAccepted: Codable {
    var `case` = "accepted"
    var durationInSeconds: Int
    var extraMonitoring: String?
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .accepted(let durationInSeconds, let extraMonitoring):
      try _CaseAccepted(durationInSeconds: durationInSeconds, extraMonitoring: extraMonitoring)
        .encode(to: encoder)
    case .rejected:
      try _NamedCase(case: "rejected").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "accepted":
      let value = try container.decode(_CaseAccepted.self)
      self = .accepted(
        durationInSeconds: value.durationInSeconds,
        extraMonitoring: value.extraMonitoring
      )
    case "rejected":
      self = .rejected
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

extension GetAdmin.SubscriptionStatus {
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

  private struct _CaseTrialing: Codable {
    var `case` = "trialing"
    var daysLeft: Int
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .trialing(let daysLeft):
      try _CaseTrialing(daysLeft: daysLeft).encode(to: encoder)
    case .complimentary:
      try _NamedCase(case: "complimentary").encode(to: encoder)
    case .paid:
      try _NamedCase(case: "paid").encode(to: encoder)
    case .overdue:
      try _NamedCase(case: "overdue").encode(to: encoder)
    case .unpaid:
      try _NamedCase(case: "unpaid").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "trialing":
      let value = try container.decode(_CaseTrialing.self)
      self = .trialing(daysLeft: value.daysLeft)
    case "complimentary":
      self = .complimentary
    case "paid":
      self = .paid
    case "overdue":
      self = .overdue
    case "unpaid":
      self = .unpaid
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

public extension UserActivity.Item {
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

  private struct _CaseScreenshot: Codable {
    var `case` = "screenshot"
    var id: Tagged<Api.Screenshot, UUID>
    var ids: [Tagged<Api.Screenshot, UUID>]
    var url: String
    var width: Int
    var height: Int
    var duringSuspension: Bool
    var createdAt: Date
    var deletedAt: Date?
  }

  private struct _CaseKeystrokeLine: Codable {
    var `case` = "keystrokeLine"
    var id: Tagged<Api.KeystrokeLine, UUID>
    var ids: [Tagged<Api.KeystrokeLine, UUID>]
    var appName: String
    var line: String
    var duringSuspension: Bool
    var createdAt: Date
    var deletedAt: Date?
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .screenshot(let unflat):
      try _CaseScreenshot(
        id: unflat.id,
        ids: unflat.ids,
        url: unflat.url,
        width: unflat.width,
        height: unflat.height,
        duringSuspension: unflat.duringSuspension,
        createdAt: unflat.createdAt,
        deletedAt: unflat.deletedAt
      ).encode(to: encoder)
    case .keystrokeLine(let unflat):
      try _CaseKeystrokeLine(
        id: unflat.id,
        ids: unflat.ids,
        appName: unflat.appName,
        line: unflat.line,
        duringSuspension: unflat.duringSuspension,
        createdAt: unflat.createdAt,
        deletedAt: unflat.deletedAt
      ).encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "screenshot":
      let value = try container.decode(_CaseScreenshot.self)
      self = .screenshot(.init(
        id: value.id,
        ids: value.ids,
        url: value.url,
        width: value.width,
        height: value.height,
        duringSuspension: value.duringSuspension,
        createdAt: value.createdAt,
        deletedAt: value.deletedAt
      ))
    case "keystrokeLine":
      let value = try container.decode(_CaseKeystrokeLine.self)
      self = .keystrokeLine(.init(
        id: value.id,
        ids: value.ids,
        appName: value.appName,
        line: value.line,
        duringSuspension: value.duringSuspension,
        createdAt: value.createdAt,
        deletedAt: value.deletedAt
      ))
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}
