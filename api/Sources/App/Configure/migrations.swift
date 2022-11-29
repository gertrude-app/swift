import Vapor

extension Configure {
  static func migrations(_ app: Application) throws {
    app.migrations.add(AdminTables())
  }
}
