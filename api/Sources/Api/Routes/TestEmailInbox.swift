import Foundation
import Vapor
import XHttp

enum TestEmailInboxRoute {
  @Sendable static func handler(_ request: Request) async throws -> Response {
    guard request.env.mode != .prod else {
      throw Abort(.notFound)
    }

    guard let API_KEY = request.env.get("TESTMAIL_API_KEY") else {
      throw Abort(.badRequest, reason: "TESTMAIL_API_KEY is not set")
    }

    let response = try await HTTP.get(
      "https://api.testmail.app/api/json?apikey=\(API_KEY)&namespace=82uii",
      decoding: TestEmailResponse.self,
      keyDecodingStrategy: .convertFromSnakeCase
    )

    return .init(
      status: .ok,
      headers: ["Content-Type": "text/html"],
      body: .init(string: response.html)
    )
  }
}

// helpers

private struct TestEmailResponse: Decodable {
  struct Email: Decodable {
    var date: Int
    var envelopeTo: String
    var envelopeFrom: String
    var subject: String
    var text: String
    var html: String?

    var secondsAgo: Int {
      Int(Date().timeIntervalSince1970 - self.dateObj.timeIntervalSince1970)
    }

    var timeAgo: String {
      let seconds = self.secondsAgo
      if seconds < 60 {
        return "\(seconds) seconds ago"
      } else if seconds < 120 {
        return "1 minute ago"
      } else {
        return "\(seconds / 60) minutes ago"
      }
    }

    var dateObj: Date {
      Date(timeIntervalSince1970: Double(self.date / 1000))
    }

    var rendered: String {
      """
      <div class="wrap">
        <ul>
          <li>
            Date: <code>\(self.dateObj.isoString)</code>&nbsp;
            <span class='received'>\(self.timeAgo)</span>
          </li>
          <li>To: <code>\(self.envelopeTo)</code></li>
          <li>From: <code>\(self.envelopeFrom)</code></li>
          <li>Subject: <code>\(self.subject)</code></li>
        </ul>
        <pre>\(self.text)</pre>
        \(self.html.map { "<div class='html'>\($0)</div>" } ?? "")
      </div>
      """
    }
  }

  var emails: [Email]

  var recent: [Email] {
    self.emails.filter { $0.secondsAgo < (60 * 5) }
  }

  var html: String {
    guard !self.recent.isEmpty else { return "<h1>No emails received in last 5 minutes</h1>" }
    return self.css + self.recent.map(\.rendered).joined(separator: "\n")
  }

  var css: String {
    """
    <style>
      code, pre { color: red; background-color: #eaeaea; padding: 2px 5px; }
      .wrap {  margin-top: 2.5em; padding: 0 2em; }
      .wrap + .wrap { padding-top: 2.5em; border-top: 1px solid #ccc; }
      .wrap:last-child { margin-bottom: 5em; }
      ul { padding-left: 0; margin-top: 0; }
      li { margin: 0.5em 0; }
      .html { background-color: #e8f9ff; padding: 1em 2em }
      .received { color: blue; font-family: monospace; }
    </style>
    """
  }
}
