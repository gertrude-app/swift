import Dependencies
import Foundation
import PairQL
import Vapor

struct CreatePendingNotificationMethod: Pair {
  static let auth: ClientAuth = .parent

  typealias Input = AdminVerifiedNotificationMethod.Config

  struct Output: PairOutput {
    let methodId: AdminVerifiedNotificationMethod.Id
  }
}

// extensions

extension AdminVerifiedNotificationMethod.Config: PairInput {}

extension CreatePendingNotificationMethod: Resolver {
  static func resolve(with config: Input, in context: AdminContext) async throws -> Output {
    let model = AdminVerifiedNotificationMethod(parentId: context.parent.id, config: config)
    let code = await with(dependency: \.ephemeral)
      .createPendingNotificationMethod(model)
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
      try await with(dependency: \.slack).send(Slack(
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
    _ = try await with(dependency: \.postmark)
      .send(template: .verifyNotificationEmail(to: email, model: .init(code: code)))

  case .text(phoneNumber: let phoneNumber):
    try await with(dependency: \.twilio).send(Text(
      to: .init(rawValue: phoneNumber),
      message: "Your verification code is \(code)"
    ))
  }
}
