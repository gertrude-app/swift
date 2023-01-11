import Foundation
import TypescriptPairQL
import Vapor

struct CreatePendingNotificationMethod: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Email: TypescriptNestable {
    let email: String
  }

  struct Text: TypescriptNestable {
    let phoneNumber: String
  }

  struct Slack: TypescriptNestable {
    let token: String
    let channelId: String
    let channelName: String
  }

  typealias Input = Union3<Email, Text, Slack>

  struct Output: TypescriptPairOutput {
    let methodId: AdminVerifiedNotificationMethod.Id
  }
}

// extensions

extension CreatePendingNotificationMethod: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    let config = AdminVerifiedNotificationMethod.Config(from: input)
    let model = AdminVerifiedNotificationMethod(adminId: context.admin.id, config: config)
    let code = await Current.ephemeral.createPendingNotificationMethod(model)
    try await sendVerification(code, for: config, in: context)
    return .init(methodId: model.id)
  }
}

extension AdminVerifiedNotificationMethod.Config {
  init(from: CreatePendingNotificationMethod.Input) {
    switch from {
    case .t1(let input):
      self = .email(email: input.email)
    case .t2(let input):
      self = .text(phoneNumber: input.phoneNumber)
    case .t3(let input):
      self = .slack(
        channelId: input.channelId,
        channelName: input.channelName,
        token: input.token
      )
    }
  }
}

// helpers

private func sendVerification(
  _ code: Int,
  for method: AdminVerifiedNotificationMethod.Config,
  in context: AdminContext
) async throws {
  switch method {
  case .slack(channelId: let channel, channelName: _, token: let token):
    do {
      try await Current.slack.send(.init(
        text: "Your verification code is `\(code)`",
        channel: channel,
        token: token
      ))
    } catch {
      throw context.error(
        id: "df619205",
        type: .unauthorized,
        debugMessage: "failed to send Slack verification code: \(error) ",
        tag: .slackVerificationFailed
      )
    }

  case .email(email: let email):
    _ = try await Current.sendGrid.send(.fromApp(
      to: email,
      subject: "Gertrude App verification code",
      html: """
      <p>
        We received a request to verify permission to send Gertrude
         App notification emails to this address.
      </p>
      <p>Your verification code is:</p>
      <p style="margin-top:2em"><code style="font-size:4em">\(code)</code></p>
      """
    ))

  case .text(phoneNumber: let phoneNumber):
    Current.twilio.send(.init(
      to: .init(rawValue: phoneNumber),
      message: "Your verification code is \(code)"
    ))
  }
}
