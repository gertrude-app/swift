import URLRouting
import Vapor

public extension Configure {
  static func router(_ app: Application) throws {
    app.webSocket(
      "app",
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

    app.get(
      "reset-9cec5bbfd7f0",
      use: ResetRoute.handler(_:)
    )

    app.post(
      "stripe-events",
      use: StripeEventsRoute.handler(_:)
    )

    app.get(
      "test-inbox",
      use: TestEmailInboxRoute.handler(_:)
    )

    // deprecated, legacy

    app.on(
      .POST,
      "graphql", "macos-app-05-2022",
      body: .collect(maxSize: "512kb"),
      use: LegacyMacAppGraphQLRoute.handler(_:)
    )

    app.post(
      "graphql",
      use: LegacyMacAppGraphQLRoute.edensHandler(_:)
    )
  }
}
