import Dependencies
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
    @Dependency(\.env) var env
    @Dependency(\.logger) var logger

    guard let token = env.get("SLACK_API_TOKEN"),
          env.mode != .staging else {
      return
    }

    let slack = XSlack.Slack.Message(
      text: message,
      channel: channel,
      username: "Gertrude Api"
    )

    if let error = await send(slack, token) {
      logger.error("Error sending slack: \(error)")
    }

    if channel == "errors" {
      logger.error("Slack sysLog to #errors: \(message)")
    } else {
      logger.info("Slack sysLog to #info: \(message)")
    }
  }

  func sysLogErr(_ message: String) async {
    await self.sysLog(to: "errors", message)
  }
}
