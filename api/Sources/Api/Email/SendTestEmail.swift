import Gertie
import Vapor

enum TestEmail {
  @Sendable static func sync(_ request: Request) async throws -> Response {
    await SyncPostmark().syncAll()
    return Response(body: .init(string: "Templates and layouts synced.\n"))
  }

  @Sendable static func send(_ request: Request) async throws -> Response {
    let env = get(dependency: \.env)
    let postmark = get(dependency: \.postmark)
    let logger = get(dependency: \.logger)
    let localDash = "http://localhost:8081"

    guard let to = env.get("TEST_EMAIL_RECIPIENT") else {
      throw Abort(
        .badRequest,
        reason: "required env var `TEST_EMAIL_RECIPIENT` not set"
      )
    }

    switch request.parameters.get("email") {
    case "initial-signup":
      try await postmark.send(template: .initialSignup(
        to: to,
        model: .init(dashboardUrl: localDash, token: .init())
      ))

    case "re-signup":
      try await postmark.send(template: .reSignup(
        to: to,
        model: .init(dashboardUrl: localDash)
      ))

    case "password-reset":
      try await postmark.send(template: .passwordReset(
        to: to,
        model: .init(dashboardUrl: localDash, token: .init())
      ))

    case "password-reset-no-account":
      try await postmark.send(template: .passwordResetNoAccount(
        to: to,
        model: .init()
      ))

    case "magic-link":
      try await postmark.send(template: .magicLink(
        to: to,
        model: .init(url: "\(localDash)/otp/\(UUID().lowercased)")
      ))

    case "magic-link-no-account":
      try await postmark.send(template: .magicLinkNoAccount(
        to: to,
        model: .init()
      ))

    case "verify-notification-email":
      try await postmark.send(template: .verifyNotificationEmail(
        to: to,
        model: .init(code: 99999)
      ))

    case "notify-suspend-filter":
      try await postmark.send(template: .notifySuspendFilter(
        to: to,
        model: .init(url: localDash, userName: "Franny")
      ))

    case "notify-unlock-request":
      try await postmark.send(template: .notifyUnlockRequest(
        to: to,
        model: .init(
          subject: "New unlock request from Franny",
          url: localDash,
          userName: "Franny",
          unlockRequests: "a new <b>network unlock request</b>"
        )
      ))

    // NB: same template, but more than one unlock request
    // probably should break this into two templates soon
    case "notify-unlock-requests":
      try await postmark.send(template: .notifyUnlockRequest(
        to: to,
        model: .init(
          subject: "3 new unlock requests from Franny",
          url: localDash,
          userName: "Franny",
          unlockRequests: "3 new <b>network unlock requests</b>"
        )
      ))

    case "notify-security-event":
      try await postmark.send(template: .notifySecurityEvent(
        to: to,
        model: .init(
          userName: "Franny",
          description: Gertie.SecurityEvent.MacApp.appQuit.toWords,
          explanation: Gertie.SecurityEvent.MacApp.appQuit.explanation
        )
      ))

    case "marketing-announcement":
      try await postmark.send(template: .v2_7_0_Announce(
        to: [to],
        model: .init(),
        dryRun: true
      ))

    case "admin-trial-ending-soon":
      try await postmark.send(template: .trialEndingSoon(to: to, model: .init()))
    case "admin-trial-ended-to-overdue":
      try await postmark.send(template: .trialEndedToOverdue(to: to, model: .init()))
    case "admin-overdue-to-unpaid":
      try await postmark.send(template: .overdueToUnpaid(to: to, model: .init()))
    case "admin-paid-to-overdue":
      try await postmark.send(template: .paidToOverdue(to: to, model: .init()))
    case "admin-unpaid-to-pending-delete":
      try await postmark.send(template: .unpaidToPendingDelete(to: to, model: .init()))
    case "admin-delete-email-unverified":
      try await postmark.send(template: .deleteEmailUnverified(to: to, model: .init()))

    default:
      throw Abort(.badRequest, reason: "unknown template email")
    }

    logger.info("Sent test email to \(to.green)")

    return Response(body: .init(string: "Email sent to \(to).\n"))
  }
}
