import Dependencies
import Vapor

enum ResetRoute {
  @Sendable static func handler(_ request: Request) async throws -> Response {
    guard request.env.mode != .prod else {
      throw Abort(.notFound)
    }

    try await Reset.run()
    let betsy = try await request.context.db.find(AdminBetsy.Ids.betsy)
    return .init(
      status: .ok,
      headers: ["Content-Type": "text/html"],
      body: .init(string: """
        <html><body><head><title>&#129532; DB Reset</title></head>
        <style>
          html { padding: 0.5em; }
          code { color: rebeccapurple; font-size: 1.2em;}
        </style>
        <h2>Reset complete</h2>
        <p>
          To auto login as "Betsy" set this <code>.env</code> variable
           in <code>./dashboard/.env</code>
        </p>
        <pre style="background: #eaeaea; padding: 1em 1em 0 1em;">
        SNOWPACK_PUBLIC_TEST_ADMIN_CREDS=\(betsy.id.lowercased):\(betsy.id.lowercased)
        </pre>
        <p>
          ...or use her email address:
           <code>\(betsy.email)</code>
        </p>
        <p>
          To test a filter suspension, use
          <a href ="\(request.env.dashboardUrl)/children/\(AdminBetsy.Ids
        .jimmysId)/suspend-filter-requests/\(AdminBetsy.Ids.suspendFilter.lowercased)">
          this route</a> in the dashboard web app:<br />
        </p>
        </body></html>
      """)
    )
  }
}
