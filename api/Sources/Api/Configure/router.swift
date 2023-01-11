import URLRouting
import Vapor

public extension Configure {
  static func router(_ app: Application) throws {
    app.get(
      "dashboard-ts-codegen",
      use: DashboardTsCodegenRoute.handler(_:)
    )
    app.post(
      "pairql", "**",
      use: PairQLRoute.handler(_:)
    )
    app.get(
      "reset-9cec5bbfd7f0",
      use: ResetRoute.handler(_:)
    )
    app.post(
      "graphql", "macos-app-05-2022",
      use: LegacyMacAppGraphQLRoute.handler(_:)
    )
    app.webSocket(
      "app",
      onUpgrade: AppWebsocket.handler(_:_:)
    )
  }
}
