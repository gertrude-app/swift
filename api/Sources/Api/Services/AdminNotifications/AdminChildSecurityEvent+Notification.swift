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

  func sendEmail(to address: String, isFallback: Bool = false) async throws {
    try await with(dependency: \.postmark)
      .send(template: .notifySecurityEvent(
        to: address,
        model: .init(
          userName: self.userName,
          description: self.desc,
          explanation: self.event.explanation
        )
      ))
  }

  func sendSlack(channel: String, token: String) async throws {
    let text = """
    Received security event: `\(desc)` for child *\(userName)*.

    \(event.explanation)
    """
    try await with(dependency: \.slack)
      .send(Slack(text: text, channel: channel, token: token))
  }
}
