import Foundation
import TypescriptPairQL
import Vapor

struct CreatePendingNotificationMethod: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct EmailInput: TypescriptNestable {
    let email: String
  }

  struct TextInput: TypescriptNestable {
    let phoneNumber: String
  }

  struct SlackInput: TypescriptNestable {
    let token: String
    let channelId: String
    let channelName: String
  }

  typealias Input = Union3<EmailInput, TextInput, SlackInput>

  struct Output: TypescriptPairOutput {
    let methodId: UUID
  }
}

// extensions

extension CreatePendingNotificationMethod: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    let method = NotificationMethod(from: input)
    let model = AdminVerifiedNotificationMethod(adminId: context.admin.id, method: method)
    let code = await Current.ephemeral.createPendingNotificationMethod(model)
    try await sendVerification(code, for: method)
    return .init(methodId: model.id.rawValue)
  }
}

extension NotificationMethod {
  init(from: CreatePendingNotificationMethod.Input) {
    switch from {
    case .a(let input):
      self = .email(email: input.email)
    case .b(let input):
      self = .text(phoneNumber: input.phoneNumber)
    case .c(let input):
      self = .slack(
        channelId: input.channelId,
        channelName: input.channelName,
        token: input.token
      )
    }
  }
}

// helpers

private func sendVerification(_ code: Int, for method: NotificationMethod) async throws {
  switch method {
  case .slack(channelId: let channelId, channelName: _, token: let token):
    let error = await Current.slack.send(.init(
      text: "Your verification code is `\(code)`",
      channel: channelId,
      username: "Gertrude App"
    ), token)
    guard error == nil else {
      throw Abort(.forbidden, reason: "[@client:slackVerificationSendFailed]")
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
