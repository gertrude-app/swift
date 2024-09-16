import XPostmark
import XSendGrid

public extension SendGrid.Email {
  init(postmark: XPostmark.Email) {
    self.init(
      to: .init(email: postmark.to),
      from: .init(email: postmark.from),
      subject: postmark.subject,
      html: postmark.html
    )
  }
}

public func isCypressTestAddress(_ email: String) -> Bool {
  email.starts(with: "e2e-user-") && email.contains("@gertrude.app")
}

public func isProdSmokeTestAddress(_ email: String) -> Bool {
  email.contains(".smoke-test-") && email.contains("@inbox.testmail.app")
}

public func isJaredTestAddress(_ email: String) -> Bool {
  email.starts(with: "jared+") && email.hasSuffix("@netrivet.com")
}

public func isTestAddress(_ email: String) -> Bool {
  isCypressTestAddress(email) || isProdSmokeTestAddress(email)
}
