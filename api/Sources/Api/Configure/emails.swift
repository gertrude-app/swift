import Vapor
import XPostmark
import XSendGrid

extension Configure {
  static func emails(_ app: Application) {
    guard app.env.mode != .test else { return }

    // configure live clients
    Current.sendGrid = .live(apiKey: app.env.sendgridApiKey)
    Current.postmark = .live(apiKey: app.env.postmarkApiKey)

    // never send emails to integration test addresses
    let sendGridSend = Current.sendGrid.send
    let postmarkSend = Current.postmark.send

    Current.sendGrid.send = { message in
      if !isCypressTestAddress(message.firstRecipient.email) {
        try await sendGridSend(message)
      }
    }

    Current.postmark.send = { email in
      if isCypressTestAddress(email.to) {
        return
      } else if isProdSmokeTestAddress(email.to) || isJaredTestAddress(email.to) {
        try await sendGridSend(.init(postmark: email))
      } else {
        try await postmarkSend(email)
      }
    }

    // to stay under 100 emails/month, only use postmark in prod
    if app.env.mode != .prod {
      Current.postmark.send = { email in
        try await Current.sendGrid.send(.init(postmark: email))
      }
    }
  }
}

// helpers

extension SendGrid.Email {
  init(postmark: XPostmark.Email) {
    self.init(
      to: .init(email: postmark.to),
      from: .init(email: postmark.from),
      subject: postmark.subject,
      html: postmark.html
    )
  }
}

private func isCypressTestAddress(_ email: String) -> Bool {
  email.starts(with: "e2e-user-") && email.contains("@gertrude.app")
}

private func isProdSmokeTestAddress(_ email: String) -> Bool {
  email.contains(".smoke-test-") && email.contains("@inbox.testmail.app")
}

private func isJaredTestAddress(_ email: String) -> Bool {
  email.starts(with: "jared+") && email.hasSuffix("@netrivet.com")
}

func isTestAddress(_ email: String) -> Bool {
  isCypressTestAddress(email) || isProdSmokeTestAddress(email)
}
