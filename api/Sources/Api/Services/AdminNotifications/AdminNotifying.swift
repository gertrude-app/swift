import Duet
import Tagged
import XSlack

protocol AdminNotifying {
  func sendText(to phoneNumber: String) async throws
  func sendSlack(channel: String, token: String) async throws
  func sendEmail(to address: String, isFallback: Bool) async throws
}

extension AdminNotifying {
  func send(with config: AdminVerifiedNotificationMethod.Config) async throws {
    switch config {
    case .text(let phoneNumber):
      try await sendText(to: phoneNumber)
    case .slack(let channelId, _, let token):
      try await sendSlack(channel: channelId, token: token)
    case .email(let address):
      try await sendEmail(to: address, isFallback: false)
    }
  }
}

// helpers and domain types

struct Slack: Equatable {
  let text: String
  let channel: String
  let token: String
}

func emailLink(url: String, text: String) -> String {
  "<a href=\"\(url)\">\(text)</a>"
}

struct Text: Equatable {
  let to: PhoneNumber
  let message: String
  typealias PhoneNumber = Tagged<Text, String>
}

extension Slack {
  static func link(to url: String, withText text: String) -> String {
    XSlack.Slack.Message.link(to: url, withText: text)
  }
}

extension Text {
  static func link(url: String) -> String {
    url
  }
}

extension UUIDStringable {
  var emailThreadDisambiguator: String {
    String(uuidString.lowercased().split(separator: "-").first ?? "")
  }
}

extension Array where Element: UUIDStringable {
  var emailThreadDisambiguator: String {
    first?.emailThreadDisambiguator ?? UUID().emailThreadDisambiguator
  }
}
