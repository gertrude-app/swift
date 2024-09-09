import Dependencies
import Foundation

extension AdminEvent.UnlockRequestSubmitted: AdminNotifying {
  func sendText(to phoneNumber: String) async throws {
    let newRequest =
      requestIds.count > 1
        ? "\(requestIds.count) new unlock requests"
        : "New unlock request"

    let message = """
    [Gertrude App] \(newRequest) from user "\(userName)".\
     View the details and approve or deny at \(url)
    """

    try await with(dependency: \.twilio)
      .send(Text(to: .init(phoneNumber), message: message))
  }

  func sendSlack(channel: String, token: String) async throws {
    let newRequest =
      requestIds.count > 1
        ? "\(requestIds.count) new *unlock requests*"
        : "New *unlock request*"

    let text = """
    \(newRequest) from user `\(userName)`.\
     \(Slack.link(to: url, withText: "Click here")) to view the details and approve or deny.
    """

    try await with(dependency: \.slack)
      .send(Slack(text: text, channel: channel, token: token))
  }

  func sendEmail(to address: String) async throws {
    let subjectPreamble =
      requestIds.count > 1
        ? "\(requestIds.count) new unlock requests from \(userName)"
        : "New unlock request from \(userName)"

    let subject = "[Gertrude App] \(subjectPreamble)"

    let unlockRequests =
      requestIds.count > 1
        ? "\(requestIds.count) new <b>network unlock requests</b>"
        : "a new <b>network unlock request</b>"

    let html = """
    User \(userName) submitted \(unlockRequests).
     \(Email.link(url: url, text: "Click here")) to view the details and approve or deny.
    """

    let email = Email.fromApp(to: address, subject: subject, html: html)
    try await Current.sendGrid.send(email)
  }
}

// helpers

extension AdminEvent.UnlockRequestSubmitted {
  private var url: String {
    if requestIds.count == 1, let first = requestIds.first {
      return self.individualRequestUrl(first)
    } else {
      return self.userUnlockRequestsUrl
    }
  }

  private var userUnlockRequestsUrl: String {
    "\(dashboardUrl)/children/\(userId.lowercased)/unlock-requests"
  }

  private func individualRequestUrl(_ requestId: UnlockRequest.Id) -> String {
    "\(self.userUnlockRequestsUrl)/\(requestId.lowercased)"
  }
}
