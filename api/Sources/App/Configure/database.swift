import Fluent
import FluentPostgresDriver
import Vapor

extension Configure {
  static func database(_ app: Application) {
    app.databases.use(
      .postgres(
        hostname: Env.get("DATABASE_HOST") ?? "localhost",
        port: 5432,
        username: Env.DATABASE_USERNAME,
        password: Env.DATABASE_PASSWORD,
        database: Env.get("\(Env.mode == .test ? "TEST_" : "")DATABASE_NAME")!
      ),
      as: .psql
    )
  }
}
