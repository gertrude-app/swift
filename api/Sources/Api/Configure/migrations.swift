import QueuesFluentDriver
import Vapor

extension Configure {
  static func migrations(_ app: Application) throws {
    app.migrations.add(AdminTables())
    app.migrations.add(KeychainTables())
    app.migrations.add(UserTables())
    app.migrations.add(ActivityTables())
    app.migrations.add(RequestTables())
    app.migrations.add(AppTables())
    app.migrations.add(MiscTables())
    app.migrations.add(JobMetadataMigrate())
  }
}
