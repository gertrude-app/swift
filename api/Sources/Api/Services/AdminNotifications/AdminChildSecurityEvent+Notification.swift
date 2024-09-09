import Dependencies
import Foundation

extension AdminEvent.MacAppSecurityEvent: AdminNotifying {
  var desc: String {
    "\(event.toWords)\(detail.map { ": \($0)" } ?? "")"
  }

  func sendText(to phoneNumber: String) async throws {
    let message = """
    [Gertrude App] Received security event: "\(desc)" for child \(userName).

    \(event.explanation)
    """

    try await with(dependency: \.twilio)
      .send(Text(to: .init(phoneNumber), message: message))
  }

  func sendEmail(to address: String) async throws {
    let subject = "[Gertrude App] Security event for child: \(userName)"

    let html = """
    Received security event: <b>\(desc)</b> for child <b>\(userName)</b>.
    <br />
    <br />
    \(event.explanation)
    """

    let email = Email.fromApp(to: address, subject: subject, html: html)
    try await Current.sendGrid.send(email)
  }

  func sendSlack(channel: String, token: String) async throws {
    let text = """
    Received security event: `\(desc)` for child *\(userName)*.

    \(event.explanation)
    """
    try await Current.slack.send(Slack(text: text, channel: channel, token: token))
  }
}
