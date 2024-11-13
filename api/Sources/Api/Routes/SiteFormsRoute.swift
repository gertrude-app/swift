import Vapor
import XCore

private struct FormData: Codable {
  enum Form: String, Codable {
    case contact
    case lockdownGuide
    case fiveThings
  }

  var form: Form
  var name: String
  var email: String
  var message: String
  var turnstileToken: String
  var subject: String?
}

enum SiteFormsRoute {
  @Sendable static func handler(_ req: Request) async throws -> Response {
    guard let data = try? req.content.decode(FormData.self) else {
      let body = ((try? await req.collectedBody()).map { $0 }) ?? "(nil)"
      with(dependency: \.logger).error("Invalid form data: `\(body)`")
      throw Abort(.badRequest, reason: "Invalid form data")
    }

    try await spamChallenge(data)

    Task {
      await with(dependency: \.slack).sysLog(data.slackText)
      try await with(dependency: \.sendgrid).send(.init(
        to: .init(email: req.env.primarySupportEmail),
        from: "Gertrude App <noreply@gertrude.app>",
        replyTo: .init(email: data.email),
        subject: data.form.name + " Submission".withEmailSubjectDisambiguator,
        text: data.emailBody
      ))
      if let backupEmail = req.env.get("BACKUP_SUPPORT_EMAIL") {
        try await with(dependency: \.sendgrid).send(.init(
          to: .init(email: backupEmail),
          from: "Gertrude App <noreply@gertrude.app>",
          replyTo: .init(email: data.email),
          subject: data.form.name + " Submission".withEmailSubjectDisambiguator,
          text: data.emailBody
        ))
      }
    }

    return Response(
      status: .ok,
      headers: ["Content-Type": "text/html"],
      body: """
      <!doctype html>
      <html>
        <head>
          <title>Form submitted</title>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            body {
              padding: 2em;
              min-height: 100vh;
              display: flex;
              flex-direction: column;
              justify-content: center;
              align-items: center;
              text-align: center;
            }
          </style>
        </head>
        <body>
          <h1>Got it!</h1>
          <p>You should hear back within 1-2 business days.</p>
        </body>
      </html>
      """
    )
  }
}

private func spamChallenge(_ data: FormData) async throws {
  switch await get(dependency: \.cloudflare).verifyTurnstileToken(data.turnstileToken) {
  case .success:
    break
  case .failure(let errorCodes, let messages):
    // TEMP: log to slack for now, delete this when i trust it more
    await with(dependency: \.slack).sysLog(to: "errors", """
    *Site form spam rejected*
    Data: `\(try JSON.encode(data))`
    Error codes: \(errorCodes.joined(separator: ", "))
    Messages: \(messages?.joined(separator: ", ") ?? "(nil)")
    """)
    throw Abort(.badRequest)
  case .error(let error):
    await with(dependency: \.slack).sysLog(to: "errors", """
    *Error verifying turnstile token*
    Data: `\(try JSON.encode(data))`
    Error: \(String(reflecting: error))
    """)
    // allow it to pass thru, as it might be a valid submission
  }
}

// extensions

extension FormData {
  var emailBody: String {
    """
    From: \(self.name), \(self.email)
    \(self.subject.map { "Subject: \($0)\n" } ?? "")
    Message:
    \(self.message)
    """
  }

  var slackText: String {
    """
    *\(self.form.name) Submission*
    _From:_ `\(self.name), \(self.email)`
    \(self.subject.map { "_Subject:_ \($0)\n" } ?? "")
    _Message:_
    \(self.message)
    """
  }
}

extension FormData.Form {
  var name: String {
    switch self {
    case .contact: return "Contact Form"
    case .lockdownGuide: return "Definitive Lockdown Guide Form"
    case .fiveThings: return "Five Things You Forgot Form"
    }
  }
}
