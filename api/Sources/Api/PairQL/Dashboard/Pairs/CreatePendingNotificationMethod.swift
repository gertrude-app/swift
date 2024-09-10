import Dependencies
import Foundation
import PairQL
import Vapor

struct CreatePendingNotificationMethod: Pair {
  static let auth: ClientAuth = .admin

  typealias Input = AdminVerifiedNotificationMethod.Config

  struct Output: PairOutput {
    let methodId: AdminVerifiedNotificationMethod.Id
  }
}

// extensions

extension AdminVerifiedNotificationMethod.Config: PairInput {}

extension CreatePendingNotificationMethod: Resolver {
  static func resolve(with config: Input, in context: AdminContext) async throws -> Output {
    let model = AdminVerifiedNotificationMethod(adminId: context.admin.id, config: config)
    let code = await Current.ephemeral.createPendingNotificationMethod(model)
    Current.logger.notice("pending notif method code `\(code)` for admin `\(context.admin.email)`")
    try await sendVerification(code, for: config, in: context)
    return .init(methodId: model.id)
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
      try await with(dependency: \.slack)
        .send(Slack(
          text: "Your verification code is `\(code)`",
          channel: channel,
          token: token
        ))
    } catch {
      throw context.error(
        id: "df619205",
        type: .unauthorized,
        debugMessage: "failed to send Slack verification code: \(error) ",
        dashboardTag: .slackVerificationFailed
      )
    }

  case .email(email: let email):
    _ = try await with(dependency: \.sendgrid).send(.fromApp(
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
    try await with(dependency: \.twilio)
      .send(Text(
        to: .init(rawValue: phoneNumber),
        message: "Your verification code is \(code)"
      ))
  }
}
