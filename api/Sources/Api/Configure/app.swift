import FluentSQL
import Vapor

import GertieIOS
import XCore

public enum Configure {
  public static func app(_ app: Application) throws {
    app.context = .shared
    app.databases.use(.from(env: app.env), as: .psql)
    app.lifecycle.use(ApiLifecyle())

    try Configure.middleware(app)
    try Configure.migrations(app)
    try Configure.router(app)
    try Configure.jobs(app)

    app.logger.notice("App environment is \(app.env.mode.coloredName)")
    if app.env.mode == .dev {
      app.logger.notice("Connected to database `\(app.env.database.name)`")
    }

    let rules: [GertieIOS.BlockRule] = [
      .urlContains("badsites.com"),
      .hostnameEquals("some site"),
      .bundleIdContains("com.example.app"),
      .both(a: .hostnameContains("foobar"), b: .urlContains("hashbaz")),
      .unless(rule: .flowTypeIs(.browser), negatedBy: [.urlContains("wow")]),
    ]
    // print(JSONEncoder().encode)
    print(try! JSON.encode(rules))
  }
}

// helpers

private struct ApiLifecyle: LifecycleHandler {
  func didBootAsync(_ app: Application) async throws {
    await with(dependency: \.ephemeral).restoreStorage()
    if app.env.mode == .dev {
      // syncing db from prod/staging does not keep search paths
      let db: SQLDatabase = app.db(.psql) as! SQLDatabase
      try await SearchPaths().up(sql: db)
    }
  }

  // NB: 7/2025 - as far as i can tell, this is not running ever
  func shutdownAsync(_ app: Application) async {
    app.logger.info("Shutting down")
    await with(dependency: \.websockets).disconnectAll()
    await with(dependency: \.ephemeral).persistStorage()
  }
}
