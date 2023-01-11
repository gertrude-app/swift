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
}
