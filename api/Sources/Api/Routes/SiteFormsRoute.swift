import Vapor

private struct FormData: Decodable {
  enum Form: String {
    case contact
    case lockdownGuide
    case fiveThings
  }

  var form: Form
  var name: String
  var email: String
  var message: String
  var subject: String?
}

enum SiteFormsRoute {
  static func handler(_ req: Request) async throws -> Response {
    guard let data = try? req.content.decode(FormData.self) else {
      await Current.slack.sysLog(to: "errors", """
      *Invalid site form data*
      Body: `\((try? await req.collectedBody()).map { $0 } ?? "(nil)")`
      """)
      throw Abort(.badRequest, reason: "Invalid form data")
    }

    Task {
      await Current.slack.sysLog(data.slackText)
      try await Current.sendGrid.send(.init(
        to: "jared@netrivet.com",
        from: "Gertrude App <noreply@gertrude.app>",
        replyTo: .init(email: data.email),
        subject: data.form.name + " Submission".withEmailSubjectDisambiguator,
        text: data.emailBody
      ))
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

extension FormData.Form: Decodable {
  var name: String {
    switch self {
    case .contact: return "Contact Form"
    case .lockdownGuide: return "Definitive Lockdown Guide Form"
    case .fiveThings: return "Five Things You Forgot Form"
    }
  }
}
