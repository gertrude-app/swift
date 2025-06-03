import Dependencies
import Foundation

extension AdminEvent.SuspendFilterRequestSubmitted: AdminNotifying {
  func sendEmail(to address: String, isFallback: Bool = false) async throws {
    try await with(dependency: \.postmark)
      .send(template: .notifySuspendFilter(
        to: address,
        model: .init(url: self.url, userName: self.childName, isFallback: isFallback)
      ))
  }

  func sendSlack(channel: String, token: String) async throws {
    let text = """
    New *suspend filter request* from user `\(self.childName)`.\
     \(Slack.link(to: self.url, withText: "Click here")) to view the details and approve or deny.
    """
    try await with(dependency: \.slack)
      .send(Slack(text: text, channel: channel, token: token))
  }

  func sendText(to phoneNumber: String) async throws {
    let message = """
    [Gertrude App] New suspend filter request from user "\(self.childName)".\
     View the details and approve or deny at \(self.url)
    """
    try await with(dependency: \.twilio)
      .send(Text(to: .init(rawValue: phoneNumber), message: message))
  }

  var url: String {
    switch self.context {
    case .macapp(computerUserId: let computerUserId, requestId: let requestId):
      "\(dashboardUrl)/children/\(computerUserId.lowercased)/suspend-filter-requests/\(requestId.lowercased)"
    case .iosapp:
      "\(dashboardUrl)/TODO" // TODO: ios filter suspension urls
    }
  }
}
