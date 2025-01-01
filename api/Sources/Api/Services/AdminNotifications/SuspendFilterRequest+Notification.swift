import Dependencies
import Foundation

extension AdminEvent.SuspendFilterRequestSubmitted: AdminNotifying {
  func sendEmail(to address: String) async throws {
    try await with(dependency: \.postmark)
      .send(template: .notifySuspendFilter(
        to: address,
        model: .init(url: self.url, userName: self.userName)
      ))
  }

  func sendSlack(channel: String, token: String) async throws {
    let text = """
    New *suspend filter request* from user `\(userName)`.\
     \(Slack.link(to: self.url, withText: "Click here")) to view the details and approve or deny.
    """
    try await with(dependency: \.slack)
      .send(Slack(text: text, channel: channel, token: token))
  }

  func sendText(to phoneNumber: String) async throws {
    let message = """
    [Gertrude App] New suspend filter request from user "\(userName)".\
     View the details and approve or deny at \(url)
    """
    try await with(dependency: \.twilio)
      .send(Text(to: .init(rawValue: phoneNumber), message: message))
  }

  var url: String {
    "\(dashboardUrl)/children/\(userId.lowercased)/suspend-filter-requests/\(requestId.lowercased)"
  }
}
