import Dependencies
import Vapor
import XPostmark

public extension DependencyValues {
  var postmark: XPostmark.Client {
    get { self[XPostmark.Client.self] }
    set { self[XPostmark.Client.self] = newValue }
  }
}

public extension XPostmark.Client {
  func send(to: String, replyTo: String? = nil, subject: String, html: String) async throws {
    try await self.sendEmail(.init(
      to: to,
      from: "Gertrude App <noreply@gertrude.app>",
      replyTo: replyTo,
      subject: subject.withEmailSubjectDisambiguator,
      htmlBody: html
    )).loggingFailure()
  }

  func send(_ email: XPostmark.Email) async throws {
    try await self.sendEmail(email).loggingFailure()
  }

  func toSuperAdmin(_ email: XPostmark.Email) {
    Task {
      try await self.sendEmail(email).loggingFailure()
    }
  }

  func toSuperAdmin(_ subject: String, _ html: String) {
    self.toSuperAdmin(.init(
      to: get(dependency: \.env).superAdminEmail,
      from: "Gertrude App <noreply@gertrude.app>",
      replyTo: nil,
      subject: subject.withEmailSubjectDisambiguator,
      htmlBody: html
    ))
  }

  func unexpected(_ id: String, _ detail: String = "") {
    self.toSuperAdmin(.unexpected(id, detail))
  }
}

public extension XPostmark.Email {
  init(to: String, subject: String, htmlBody: String) {
    self.init(
      to: to,
      from: "Gertrude App <noreply@gertrude.app>",
      subject: subject,
      htmlBody: htmlBody
    )
  }

  static func unexpected(_ id: String, _ detail: String = "") -> Self {
    let search = "https://github.com/search?q=repo%3Agertrude-app%2Fswift%20\(id)&type=code"
    return .init(
      to: get(dependency: \.env).superAdminEmail,
      from: "Gertrude App <noreply@gertrude.app>",
      subject: "Gertrude API unexpected event".withEmailSubjectDisambiguator,
      htmlBody: "id: <code><a href='\(search)'>\(id)</a></code><br/><br/>\(detail)"
    )
  }
}

extension Result where Success == Void, Failure == XPostmark.Client.Error {
  func loggingFailure() async throws {
    switch self {
    case .failure(let err):
      with(dependency: \.logger).error("Error sending email: \(err)")
      await with(dependency: \.slack).sysLog("Error sending email: \(err)")
      throw err
    case .success:
      break
    }
  }
}

extension XPostmark.Client: DependencyKey {
  public static var liveValue: XPostmark.Client {
    let env = Env.fromProcess(mode: try? Vapor.Environment.detect())
    return XPostmark.Client.live(apiKey: env.postmarkApiKey)
  }
}

func isCypressTestAddress(_ email: String) -> Bool {
  email.starts(with: "e2e-user-") && email.contains("@gertrude.app")
}

func isProdSmokeTestAddress(_ email: String) -> Bool {
  email.contains(".smoke-test-") && email.contains("@inbox.testmail.app")
}

func isJaredTestAddress(_ email: String) -> Bool {
  email.starts(with: "jared+") && email.hasSuffix("@netrivet.com")
}

func isTestAddress(_ email: String) -> Bool {
  isCypressTestAddress(email) || isProdSmokeTestAddress(email)
}
