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

    app.post(
      "site-forms",
      use: SiteFormsRoute.handler(_:)
    )

    app.on(
      .POST,
      "pairql", ":domain", ":operation",
      body: .collect(maxSize: "512kb"),
      use: PairQLRoute.handler(_:)
    )

    #if DEBUG
      if app.env.mode == .dev {
        app.get(
          "send-test-email", ":email",
          use: TestEmail.send(_:)
        )
        app.get(
          "sync-email-templates",
          use: TestEmail.sync(_:)
        )
      }
    #endif

    app.get(
      "releases",
      use: ReleasesRoute.handler(_:)
    )

    if let suffix = app.env.get("RESET_ROUTE_SUFFIX") {
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
