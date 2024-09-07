import Dependencies
import Rainbow
import Vapor

extension Configure {
  static func env(_ app: Application) {
    guard app.env.mode != .test else { return }

    Current.logger = app.logger
    Current.aws = .live(
      accessKeyId: app.env.s3.key,
      secretAccessKey: app.env.s3.secret,
      endpoint: app.env.s3.endpoint,
      bucket: app.env.s3.bucket
    )

    app.databases.use(.from(env: app.env), as: .psql)

    Current.logger.notice("App environment is \(app.env.mode.coloredName)")

    if app.env.mode == .dev {
      Current.logger.notice("Connected to database `\(app.env.database.name)`")
    }
  }
}
