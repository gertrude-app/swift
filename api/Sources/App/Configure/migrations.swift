import Vapor

extension Configure {
  static func migrations(_ app: Application) throws {
    app.migrations.add(AdminTables())

    if app.environment != .production {
      try app.autoMigrate().wait()
    }
  }
}
