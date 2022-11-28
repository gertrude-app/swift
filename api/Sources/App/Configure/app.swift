import Vapor

public enum Configure {
  public static func app(_ app: Application) throws {
    Configure.env(app)
    Configure.database(app)
    Configure.middleware(app)
    try Configure.migrations(app)
  }
}
