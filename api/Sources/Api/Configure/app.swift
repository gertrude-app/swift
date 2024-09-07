import Vapor

public enum Configure {
  public static func app(_ app: Application) throws {
    app.context = .shared
    Configure.env(app)
    Configure.emails(app)
    Configure.middleware(app)
    try Configure.migrations(app)
    try Configure.router(app)
    try Configure.jobs(app)
    Configure.lifecycleHandlers(app)
  }
}
