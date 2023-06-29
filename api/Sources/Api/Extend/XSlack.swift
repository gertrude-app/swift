import XSlack

extension XSlack.Slack.Client {
  struct SendError: Error {
    let message: String
  }

  func send(_ apiSlack: Api.Slack) async throws {
    let slack = XSlack.Slack.Message(
      text: apiSlack.text,
      channel: apiSlack.channel,
      username: "Gertrude App"
    )
    if let error = await send(slack, apiSlack.token) {
      throw SendError(message: error)
    }
  }

  func sysLog(to channel: String = "info", _ message: String) async {
    guard let token = Env.get("SLACK_API_TOKEN"), Env.mode != .staging else {
      return
    }

    let slack = XSlack.Slack.Message(
      text: message,
      channel: channel,
      username: "Gertrude Api"
    )

    if let error = await send(slack, token) {
      Current.logger.error("Error sending slack: \(error)")
    }
  }
}
