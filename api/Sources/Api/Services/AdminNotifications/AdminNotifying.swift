import Duet
import Tagged
import XSendGrid
import XSlack

protocol AdminNotifying {
  func sendEmail(to address: String) async throws
  func sendSlack(channel: String, token: String) async throws
  func sendText(to phoneNumber: String) async throws
}

extension AdminNotifying {
  func send(with config: AdminVerifiedNotificationMethod.Config) async throws {
    switch config {
    case .email(let address):
      try await sendEmail(to: address)
    case .slack(let channelId, _, let token):
      try await sendSlack(channel: channelId, token: token)
    case .text(let phoneNumber):
      try await sendText(to: phoneNumber)
    }
  }
}

// helpers and domain types

typealias Email = SendGrid.Email

struct Slack: Equatable {
  let text: String
  let channel: String
  let token: String
}

extension Email {
  static func link(url: String, text: String) -> String {
    "<a href=\"\(url)\">\(text)</a>"
  }

  static func fromApp(to: String, subject: String, html: String) -> Email {
    .init(
      to: .init(email: to),
      from: .init(email: "noreply@gertrude.app", name: "Gertrude App"),
      subject: subject.withEmailSubjectDisambiguator,
      html: html
    )
  }

  static func toJared(_ subject: String, _ html: String) -> Email {
    .init(
      to: .init(email: "jared@netrivet.com"),
      from: .init(email: "noreply@gertrude.app", name: "Gertrude App"),
      subject: "Gertrude " + subject.withEmailSubjectDisambiguator,
      html: html
    )
  }

  static func unexpected(_ id: String, _ detail: String = "") -> Email {
    let search = "https://github.com/search?q=repo%3Agertrude-app%2Fswift%20\(id)&type=code"
    return .init(
      to: .init(email: "jared@netrivet.com"),
      from: .init(email: "noreply@gertrude.app", name: "Gertrude App"),
      subject: "Gertrude API unexpected event".withEmailSubjectDisambiguator,
      html: "id: <code><a href='\(search)'>\(id)</a></code><br/><br/>\(detail)"
    )
  }
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
