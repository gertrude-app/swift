import Vapor

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
  }
}

// helpers

private struct ApiLifecyle: LifecycleHandler {
  func shutdownAsync(_ app: Application) async {
    app.logger.info("Shutting down")
    await with(dependency: \.websockets).disconnectAll()
  }
}
