import URLRouting
import Vapor

public extension Configure {
  static func router(_ app: Application) throws {
    app.webSocket(
      "app-websocket",
      onUpgrade: AppWebsocket.handler(_:_:)
    )

    app.get(
      "appcast.xml",
      use: AppcastRoute.handler(_:)
    )

    app.get(
      "dashboard-ts-codegen",
      use: DashboardTsCodegenRoute.handler(_:)
    )

    app.on(
      .POST,
      "pairql", ":domain", ":operation",
      body: .collect(maxSize: "512kb"),
      use: PairQLRoute.handler(_:)
    )

    app.get(
      "releases",
      use: ReleasesRoute.handler(_:)
    )

    if let suffix = Env.get("RESET_ROUTE_SUFFIX") {
      app.get(
        "reset-\(suffix)",
        use: ResetRoute.handler(_:)
      )
    }

    app.post(
      "stripe-events",
      use: StripeEventsRoute.handler(_:)
    )

    app.get(
      "test-inbox",
      use: TestEmailInboxRoute.handler(_:)
    )
  }
}
