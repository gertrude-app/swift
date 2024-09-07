import Dependencies
import DuetSQL
import Vapor

struct AppContext {
  var db: any DuetSQL.Client
  var env: Env
}

extension AppContext {
  static var shared: AppContext {
    @Dependency(\.db) var db
    @Dependency(\.env) var env
    return .init(db: db, env: env)
  }
}

extension AppContext: StorageKey {
  typealias Value = AppContext
}

extension Vapor.Application {
  var context: AppContext {
    get { self.storage[AppContext.self] ?? .shared }
    set { self.storage[AppContext.self] = newValue }
  }

  var env: Env {
    self.context.env
  }
}

extension Request {
  var id: String {
    if let value = logger[metadataKey: "request-id"],
       let uuid = UUID(uuidString: "\(value)") {
      return uuid.uuidString.lowercased()
    } else {
      return UUID().uuidString.lowercased()
    }
  }

  var context: AppContext {
    self.application.context
  }

  var env: Env {
    self.application.context.env
  }

  // get the entire request body as a string, collecting if necessary
  // @see https://stackoverflow.com/questions/70120989
  func collectedBody(max: Int? = nil) async throws -> String? {
    if let body = body.string {
      return body
    }

    guard let buffer = try await body.collect(max: max).get() else {
      return nil
    }

    return String(data: Data(buffer: buffer), encoding: .utf8)
  }

  func userToken() async throws -> UserToken {
    guard let header = headers.first(name: .authorization),
          let uuid = UUID(authorizationHeader: header) else {
      throw Abort(.badRequest, reason: "invalid user auth token")
    }

    let userToken = try? await UserToken.query()
      .where(.value == uuid)
      .first()

    guard let userToken = userToken else {
      // the mac app looks for this specific error message (for now, at least)
      throw Abort(.unauthorized, reason: "user auth token not found")
    }

    return userToken
  }

  var dashboardUrl: String { headers.dashboardUrl }

  var ipAddress: String? {
    let ip = headers.first(name: "CF-Connecting-IP") // NB: cloudflare proxy
      ?? headers.first(name: .xForwardedFor)
      ?? headers.first(name: "X-Real-IP")
      ?? remoteAddress?.ipAddress
    // sometimes we get multiple ip addresses, like `1.2.3.4, 1.2.3.5`
    return ip?.split(separator: ",").first.map { String($0) }
  }
}

// helpers

private extension UUID {
  init?(authorizationHeader: String) {
    let prefix = "Bearer "
    guard authorizationHeader.hasPrefix(prefix) else { return nil }
    self.init(uuidString: String(authorizationHeader.dropFirst(prefix.count)))
  }
}
