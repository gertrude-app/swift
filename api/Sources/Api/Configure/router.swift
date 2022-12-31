import URLRouting
import Vapor
import VaporRouting

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
  }
}
