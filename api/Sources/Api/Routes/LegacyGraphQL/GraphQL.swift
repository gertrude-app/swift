import DuetSQL
import Vapor

private struct Operation: Decodable {
  let operationName: String
}

enum LegacyMacAppGraphQLRoute {
  static func handler(_ request: Request) async throws -> Response {
    let operationName = try request.content.decode(Operation.self).operationName
    print("Legacy GraphQL operation: \(operationName)")
    switch operationName {
    case "AppInstructions":
      return try await appInstructions(request)
    default:
      return .init(status: .noContent)
    }
  }

  static func context(_ request: Request) async throws -> UserContext {
    guard let header = request.headers.first(name: .authorization),
          let token = UUID(authorizationHeader: header) else {
      throw Abort(.badRequest, reason: "invalid user auth token")
    }

    let userToken = try? await Current.db.query(UserToken.self)
      .where(.value == token)
      .first()

    guard let userToken = userToken else {
      throw Abort(.unauthorized, reason: "protected auth token not found")
    }

    let user = try await Current.db.find(userToken.userId)
    return .init(requestId: request.id, user: user)
  }
}

// extensions

private extension UUID {
  init?(authorizationHeader: String) {
    let prefix = "Bearer "
    guard authorizationHeader.hasPrefix(prefix) else { return nil }
    self.init(uuidString: String(authorizationHeader.dropFirst(prefix.count)))
  }
}
