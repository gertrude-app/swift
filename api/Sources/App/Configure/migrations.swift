import Vapor

extension Configure {
  static func migrations(_ app: Application) throws {
    // app.migrations.add(Import())

    if app.environment != .production {
      try app.autoMigrate().wait()
    }
  }
}
