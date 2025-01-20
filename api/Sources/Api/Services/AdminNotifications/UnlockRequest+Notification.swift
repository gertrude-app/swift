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
    let subject = requestIds.count > 1
      ? "\(requestIds.count) new unlock requests from \(userName)"
      : "New unlock request from \(userName)"

    let unlockRequests = requestIds.count > 1
      ? "\(requestIds.count) new <b>unlock requests</b>"
      : "a new <b>unlock request</b>"

    try await with(dependency: \.postmark)
      .send(template: .notifyUnlockRequest(
        to: address,
        model: .init(
          subject: subject,
          url: self.url,
          userName: self.userName,
          unlockRequests: unlockRequests
        )
      ))
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
