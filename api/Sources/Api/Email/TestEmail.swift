import Gertie
import Vapor

#if DEBUG
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
          model: .init(url: localDash, userName: "Franny", isFallback: false)
        ))

      case "notify-unlock-request":
        try await postmark.send(template: .notifyUnlockRequest(
          to: to,
          model: .init(
            subject: "New unlock request from Franny",
            url: localDash,
            userName: "Franny",
            unlockRequests: "a new <b>unlock request</b>",
            isFallback: false
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
            unlockRequests: "3 new <b>unlock requests</b>",
            isFallback: false
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
        let batch1 = [
          "rafibiswas2015@gmail.com",
          "mardanmiller@gmail.com",
          "carson.quesenberry@gmail.com",
          "nick@reachproductions.net",
          "brandon_j_stubbs@msn.com",
          "dove25hs@gmail.com",
          "juawana.gaddis@gmail.com",
          "yazid-13210@hotmail.fr",
          "william.hussman@gmail.com",
          "med.amine.ayadi@icloud.com",
          "lolilight84@gmail.com",
          "yalshaya@gmail.com",
          "weissomarrealtor@gmail.com",
          "chichianghsu@yahoo.com",
          "saldana.antonio1@icloud.com",
          "maxhollmann@icloud.com",
          "matthewdbowman@gmail.com",
          "ngominh99hp@gmail.com",
          "sharonsam2003@gmail.com",
          "jetdrew05@gmail.com",
          "rowanvolino@gmail.com",
          "mathiasabby@gmail.com",
          "jared+2@netrivet.com",
        ]
        try await postmark.send(template: .v2_7_0_Announce(
          to: batch1,
          model: .init(),
          dryRun: false
        ))

      case "admin-trial-ending-soon":
        try await postmark
          .send(template: .trialEndingSoon(to: to, model: .init(length: 21, remaining: 3)))

      case "admin-trial-ended-to-overdue":
        try await postmark.send(template: .trialEndedToOverdue(to: to, model: .init(length: 21)))

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

    @Sendable static func web(_ request: Request) async throws -> Response {
      switch request.parameters.get("email") {
      case "initial-signup":
        return write(template: InitialSignup.self)
      case "re-signup":
        return write(template: ReSignup.self)
      case "password-reset":
        return write(template: PasswordReset.self)
      case "password-reset-no-account":
        return write(template: PasswordResetNoAccount.self)
      case "magic-link":
        return write(template: MagicLink.self)
      case "magic-link-no-account":
        return write(template: MagicLinkNoAccount.self)
      case "verify-notification-email":
        return write(template: VerifyNotificationEmail.self)
      case "notify-suspend-filter":
        return write(template: NotifySuspendFilter.self)
      case "notify-unlock-request":
        return write(template: NotifyUnlockRequest.self)
      case "notify-security-event":
        return write(template: NotifySecurityEvent.self)
      case "marketing-announcement":
        return write(template: V2_7_0_Announce.self)
      case "admin-trial-ending-soon":
        return write(template: AccountLifecycle.TrialEndingSoon.self)
      case "admin-trial-ended-to-overdue":
        return write(template: AccountLifecycle.TrialEndedToOverdue.self)
      case "admin-overdue-to-unpaid":
        return write(template: AccountLifecycle.OverdueToUnpaid.self)
      case "admin-paid-to-overdue":
        return write(template: AccountLifecycle.PaidToOverdue.self)
      case "admin-unpaid-to-pending-delete":
        return write(template: AccountLifecycle.UnpaidToPendingDelete.self)
      case "admin-delete-email-unverified":
        return write(template: AccountLifecycle.DeleteEmailUnverified.self)
      default:
        throw Abort(.badRequest, reason: "unknown template email")
      }
    }
  }

  // helpers

  func write<T: TemplateEmailModel>(template T: T.Type) -> Response {
    var lines = devHtml(template: T.self).split(separator: "\n")
    lines.removeFirst(2)
    let html = "<!DOCTYPE html>\n<html>" + lines.joined(separator: "\n") + "\n"
    let fm = FileManager.default
    let path = fm.currentDirectoryPath + "/../index.html"
    let current = (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
    if current == html {
      return Response(body: .init(string: ""))
    } else if fm.createFile(atPath: path, contents: html.data(using: .utf8), attributes: nil) {
      return Response(body: .init(string: "<root>/index.html regenerated\n"))
    } else {
      return Response(body: .init(string: "ERROR writing file\n"))
    }
  }

  func devHtml<T: TemplateEmailModel>(template T: T.Type) -> String {
    let templateInput = T.pmTemplateInput()
    let layout = EmailLayout(slug: templateInput.LayoutTemplate!)!
    return layout.pmTemplateInput().HtmlBody.replacingOccurrences(
      of: "{{{ @content }}}",
      with: templateInput.HtmlBody
    )
  }
#endif
