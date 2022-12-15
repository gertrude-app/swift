import Duet
import Fluent
import Foundation
import Tagged
import XSendGrid
// import XSlack

typealias Email = SendGrid.Email

protocol Notification {
  // func slack(channel: String, token: String) -> Slack
  func email(email: String) -> Email
  func text(phoneNumber: String) -> Text
}

struct Slack {
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
      from: .init(email: "notifications@gertrude-app.com", name: "Gertrude App"),
      subject: subject.withEmailSubjectDisambiguator,
      html: html
    )
  }

  static func toJared(_ subject: String, _ html: String) -> Email {
    .init(
      to: .init(email: "jared@netrivet.com"),
      from: .init(email: "notifications@gertrude-app.com", name: "Gertrude App"),
      subject: subject.withEmailSubjectDisambiguator,
      html: html
    )
  }
}

struct Text {
  let to: PhoneNumber
  let message: String
  typealias PhoneNumber = Tagged<Text, String>

  var recipientI164: String {
    "+1\(to.rawValue.filter(\.isNumber).drop(while: { $0 == "1" }))"
  }
}

extension Slack {
  // var xSlackMessage: XSlack.Slack.Message {
  //   .init(text: text, channel: channel, username: "Gertrude")
  // }

  // static func link(to url: String, withText text: String) -> String {
  //   XSlack.Slack.Message.link(to: url, withText: text)
  // }
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
