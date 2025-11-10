import Vapor
import XCore

private struct FormData: Codable {
  enum Form: String, Codable {
    case contact
    case lockdownGuide
    case fiveThings
  }

  enum App: String, Codable {
    case mac
    case ios
    case podcasts
    case unsure

    var display: String {
      switch self {
      case .mac: "Gertrude Mac"
      case .ios: "Gertrude iOS"
      case .podcasts: "Gertrude AM"
      case .unsure: "(not sure)"
      }
    }
  }

  var form: Form
  var app: App?
  var name: String
  var email: String
  var message: String
  var turnstileToken: String
  var subject: String?
}

enum SiteFormsRoute {
  @Sendable static func handler(_ req: Request) async throws -> Response {
    guard let data = try? req.content.decode(FormData.self) else {
      let body = await ((try? req.collectedBody()).map(\.self)) ?? "(nil)"
      with(dependency: \.logger).error("Invalid form data: `\(body)`")
      throw Abort(.badRequest, reason: "Invalid form data")
    }

    if get(dependency: \.env).mode != .dev {
      try await spamChallenge(data)
    }

    Task {
      await with(dependency: \.slack).internal(.contactForm, data.slackText)
      try await with(dependency: \.postmark).send(
        to: req.env.primarySupportEmail,
        replyTo: data.email,
        subject: data.form.name + " Submission",
        html: data.emailBody,
      )
      if let backupEmail = req.env.get("BACKUP_SUPPORT_EMAIL") {
        try await with(dependency: \.postmark).send(
          to: backupEmail,
          replyTo: data.email,
          subject: data.form.name + " Submission",
          html: data.emailBody,
        )
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
      """,
    )
  }
}

private func spamChallenge(_ data: FormData) async throws {
  switch await get(dependency: \.cloudflare)
    .verifyTurnstileToken(data.turnstileToken) {
  case .success:
    break
  case .failure:
    throw Abort(.badRequest)
  case .error(let error):
    try await with(dependency: \.slack).error("""
    *Error verifying turnstile token*
    Data: `\(JSON.encode(data))`
    Error: \(String(reflecting: error))
    """)
    // allow it to pass thru, as it might be a valid submission
  }
}

// extensions

extension FormData {
  var emailBody: String {
    """
    From: \(self.name), \(self.email)<br />
    \(self.subject.map { "Subject: \($0)<br />" } ?? "")
    \(self.app.map { "App: \($0.display)<br />" } ?? "")
    Message:
    \(self.message.replacingOccurrences(of: "\n", with: "<br />"))
    """
  }

  var slackText: String {
    """
    *\(self.form.name) Submission*
    _From:_ `\(self.name), \(self.email)`
    \(self.subject.map { "_Subject:_ \($0)" } ?? "")
    \(self.app.map { "_App:_ `\($0.display)`" } ?? "")
    _Message:_
    \(self.message)
    """
  }
}

extension FormData.Form {
  var name: String {
    switch self {
    case .contact: "Contact Form"
    case .lockdownGuide: "Definitive Lockdown Guide Form"
    case .fiveThings: "Five Things You Forgot Form"
    }
  }
}
