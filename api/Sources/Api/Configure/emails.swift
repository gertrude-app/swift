import Vapor

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
      if !isTestAddress(message.firstRecipient.email) {
        try await sendGridSend(message)
      }
    }
    Current.postmark.send = { email in
      if !isTestAddress(email.to) {
        try await postmarkSend(email)
      }
    }

    // to stay under 100 emails/month, only use postmark in prod
    if Env.mode != .prod {
      Current.postmark.send = { email in
        try await Current.sendGrid.send(.init(
          to: .init(email: email.to),
          from: .init(email: email.from),
          subject: email.subject,
          html: email.html
        ))
      }
    }
  }
}

// helpers

private func isTestAddress(_ email: String) -> Bool {
  email.starts(with: "e2e-test-") && email.contains("@gertrude.app")
}
