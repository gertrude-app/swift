import Vapor
import XPostmark
import XSendGrid

extension Configure {
  static func emails(_ app: Application) {
    guard Env.mode != .test else { return }

    // configure live clients
    Current.sendGrid = .live(apiKey: Env.SENDGRID_API_KEY)
    Current.postmark = .live(apiKey: Env.POSTMARK_API_KEY)

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
      } else if isProdSmokeTestAddress(email.to) {
        try await sendGridSend(.init(postmark: email))
      } else {
        try await postmarkSend(email)
      }
    }

    // to stay under 100 emails/month, only use postmark in prod
    if Env.mode != .prod {
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
  email.starts(with: "e2e-test-") && email.contains("@gertrude.app")
}

private func isProdSmokeTestAddress(_ email: String) -> Bool {
  email.starts(with: "82uii.smoke-test-") && email.contains("@inbox.testmail.app")
}

func isTestAddress(_ email: String) -> Bool {
  isCypressTestAddress(email) || isProdSmokeTestAddress(email)
}
