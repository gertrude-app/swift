import Fluent
import FluentPostgresDriver
import Vapor

extension Configure {
  static func middleware(_ app: Application) {
    app.middleware = .init()
    app.middleware.use(corsMiddleware(app), at: .beginning)
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
  }
}

private func corsMiddleware(_ app: Application) -> CORSMiddleware {
  let configuration = CORSMiddleware.Configuration(
    allowedOrigin: app.environment == .production ? .any(["https://dash.gertrude.app"]) : .all,
    allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
    allowedHeaders: [
      .accept,
      .authorization,
      .contentType,
      .origin,
      .xRequestedWith,
      .userAgent,
      .accessControlAllowOrigin,
      .referer,
      .xDashboardUrl,
      .xAdminToken,
      .xUserToken,
      .xAppVersion,
    ]
  )

  return CORSMiddleware(configuration: configuration)
}