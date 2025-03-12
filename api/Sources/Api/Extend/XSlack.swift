import ConcurrencyExtras
import Dependencies
import Foundation
import XSlack

extension XSlack.Slack.Client {
  struct SendError: Error {
    let message: String
  }

  enum InternalChannel: String {
    case macosOnboarding = "macos-onboarding"
    case macosLogs = "macos-logs"
    case iosOnboarding = "ios-onboarding"
    case iosLogs = "ios-logs"
    case unexpectedErrors = "unexpected-errors"
    case expectedErrors = "expected-errors"
    case stripe
    case signups
    case contactForm = "contact-form"
    case info
    case debug
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

  func `internal`(_ channel: InternalChannel, _ message: String) async {
    @Dependency(\.env) var env
    @Dependency(\.logger) var logger

    guard let token = env.get("SLACK_API_TOKEN"),
          env.mode != .staging else {
      return
    }

    let slack = XSlack.Slack.Message(
      text: message,
      channel: channel.rawValue,
      username: "Gertrude Api"
    )

    if limitHelper.canSend(), let error = await self.sendInternal(slack, token) {
      logger.error("Error sending slack: \(error)")
    }

    if channel == .unexpectedErrors {
      logger.error("Slack sysLog to #\(channel): \(message)")
    } else {
      logger.info("Slack sysLog to #\(channel): \(message)")
    }
  }

  func error(_ message: String) async {
    await self.internal(.unexpectedErrors, message)
  }

  private func sendInternal(_ slack: XSlack.Slack.Message, _ token: String) async -> String? {
    if slack.channel == InternalChannel.debug.rawValue {
      return await self.send(slack, token)
    }
    var copy = slack
    copy.channel = InternalChannel.debug.rawValue
    let debug = copy
    async let e1 = self.send(slack, token)
    async let e2 = self.send(debug, token)
    let (error1, error2) = await (e1, e2)
    return error1 ?? error2
  }
}

// NB: count/date will reset on a new deploy or api
// crash/restart but should be good enough for now
struct LimitHelper: Sendable {
  private var data: LockIsolated<(Int, Date)> = .init((0, Date()))

  func canSend(num: Int = 2) -> Bool {
    let (count, start) = self.data.value
    if Date() - .hours(24) > start {
      self.data.withValue { $0 = (num, Date()) }
      return true
    } else if count < 3000 {
      self.data.withValue { $0 = (count + num, start) }
      return true
    } else if count == Int.max {
      return false
    } else {
      self.data.withValue { $0 = (Int.max, start) }
      with(dependency: \.postmark).toSuperAdmin(
        "internal slack rate limit reached",
        "see server logs, db for un-slacked events"
      )
      return false
    }
  }
}

let limitHelper = LimitHelper()
