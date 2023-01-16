import Foundation

extension AdminEvent.SuspendFilterRequestSubmitted: AdminNotifying {
  func sendEmail(to address: String) async throws {
    let subject =
      "[Gertrude App] New suspend filter request from \(userName)".withEmailSubjectDisambiguator
    let html = """
    User \(userName) submitted a new <b>suspend filter request</b>.
     \(Email.link(url: url, text: "Click here")) to view the details and approve or deny.
    """
    try await Current.sendGrid.send(Email.fromApp(to: address, subject: subject, html: html))
  }

  func sendSlack(channel: String, token: String) async throws {
    let text = """
    New *suspend filter request* from user `\(userName)`.\
     \(Slack.link(to: url, withText: "Click here")) to view the details and approve or deny.
    """
    try await Current.slack.send(Slack(text: text, channel: channel, token: token))
  }

  func sendText(to phoneNumber: String) async throws {
    let message = """
    [Gertrude App] New suspend filter request from user "\(userName)".\
     View the details and approve or deny at \(url)
    """
    Current.twilio.send(Text(to: .init(rawValue: phoneNumber), message: message))
  }

  var url: String {
    "\(dashboardUrl)/suspend-filter-requests/\(requestId.lowercased)"
  }
}