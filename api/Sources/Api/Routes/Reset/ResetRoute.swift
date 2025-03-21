import Dependencies
import Vapor

struct ResetCommand: AsyncCommand {
  struct Signature: CommandSignature {}
  var help: String { "Reset staging data" }

  func run(using context: CommandContext, signature: Signature) async throws {
    guard get(dependency: \.env).mode != .prod else {
      fatalError("`reset` is only allowed in non-prod environments")
    }
    try await Reset.run()
    try await SyncStagingDataCommand().run(using: context, signature: .init())
  }
}

enum ResetRoute {
  @Sendable static func handler(_ request: Request) async throws -> Response {
    guard request.env.mode != .prod else {
      throw Abort(.notFound)
    }

    try await Reset.run()
    try await SyncStagingDataCommand()
      .exec(client: request.application.http.client.shared)
      .mapError { Abort(.internalServerError, reason: $0.message) }
      .get()

    let betsy = try await request.context.db.find(AdminBetsy.Ids.betsy)
    let dashUrl = request.env.dashboardUrl
    let jimmysId = AdminBetsy.Ids.jimmysId
    let filterReqId = AdminBetsy.Ids.suspendFilter.lowercased

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
        VITE_ADMIN_CREDS=\(betsy.id.lowercased):\(betsy.id.lowercased)
        </pre>
        <p>
          ...or use her email address:
           <code>\(betsy.email)</code>
        </p>
        <p>
          To test a filter suspension, use
          <a href ="\(dashUrl)/children/\(jimmysId)/suspend-filter-requests/\(filterReqId)">
          this route</a> in the dashboard web app:<br />
        </p>
        </body></html>
      """)
    )
  }
}
