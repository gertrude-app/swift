import DuetSQL
import FluentPostgresDriver
import Vapor

extension Configure {
  static func database(_ app: Application) {
    let dbPrefix = Env.mode == .test ? "TEST_" : ""

    app.databases.use(
      .postgres(
        configuration: .init(
          hostname: Env.get("DATABASE_HOST") ?? "localhost",
          username: Env.DATABASE_USERNAME,
          password: Env.DATABASE_PASSWORD,
          database: Env.get("\(dbPrefix)DATABASE_NAME")!,
          tls: .disable
        )
      ),
      as: .psql
    )

    Current.db = LiveClient(sql: app.db as! SQLDatabase)
  }
}
