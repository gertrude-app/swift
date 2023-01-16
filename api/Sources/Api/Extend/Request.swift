import DuetSQL
import Vapor

extension Request {
  var id: String {
    if let value = logger[metadataKey: "request-id"],
       let uuid = UUID(uuidString: "\(value)") {
      return uuid.uuidString.lowercased()
    } else {
      return UUID().uuidString.lowercased()
    }
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

    let userToken = try? await Current.db.query(UserToken.self)
      .where(.value == uuid)
      .first()

    guard let userToken = userToken else {
      // the mac app looks for this specific error message (for now, at least)
      throw Abort(.unauthorized, reason: "user auth token not found")
    }

    return userToken
  }

  var dashboardUrl: String { headers.dashboardUrl }
}

// helpers

private extension UUID {
  init?(authorizationHeader: String) {
    let prefix = "Bearer "
    guard authorizationHeader.hasPrefix(prefix) else { return nil }
    self.init(uuidString: String(authorizationHeader.dropFirst(prefix.count)))
  }
}
