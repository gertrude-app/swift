import DuetSQL
import MacAppRoute
import Vapor
import XCore

private struct Operation: Decodable {
  let operationName: String
}

enum LegacyMacAppGraphQLRoute {
  static func handler(_ request: Request) async throws -> Response {
    let operationName = try request.content.decode(Operation.self).operationName
    print("Legacy GraphQL operation: \(operationName)")
    switch operationName {
    case "AccountStatus":
      return try await accountStatus(request)
    case "AppInstructions":
      return try await appInstructions(request)
    case "ConnectApp":
      return try await connectApp(request)
    case "CreateSuspendFilterRequest":
      return try await createSuspendFilterRequest(request)
    default:
      return .init(status: .noContent)
    }
  }

  // implementations

  static func accountStatus(_ request: Request) async throws -> Response {
    let context = try await context(request)
    let output = try await GetAccountStatus.resolve(in: context)
    let json = """
    {
      "user": {
        "admin": {
          "accountStatus": "\(output.status)"
        }
      }
    }
    """
    return .init(graphqlData: json)
  }

  static func appInstructions(_ request: Request) async throws -> Response {
    struct Key: Encodable {
      let jsonString: String
    }

    struct KeyRecord: Encodable {
      let id: String
      let key: Key
    }

    let context = try await context(request)
    let output = try await RefreshRules.resolve(in: context)
    let records = try output.keys.map { key in
      KeyRecord(
        id: key.id.lowercased,
        key: .init(jsonString: try JSON.encode(key.key))
      )
    }

    let json = """
    {
      "user": {
        "keyloggingEnabled": \(output.keyloggingEnabled),
        "screenshotsEnabled": \(output.screenshotsEnabled),
        "screenshotsFrequency": \(output.screenshotsFrequency),
        "screenshotsResolution": \(output.screenshotsResolution),
        "keychains": [
          "keyRecords": \(try JSON.encode(records))
        ]
      },
      "manifest": {
        "jsonString": \(try JSON.encode(output.appManifest))
      }
    }
    """
    return .init(graphqlData: json)
  }

  static func connectApp(_ request: Request) async throws -> Response {
    let input = try request.content.decode(ConnectApp.Input.self)
    let output = try await ConnectApp.resolve(with: input, in: .init(requestId: request.id))
    let json = """
    {
      "connection": {
        "token": {
          "value": "\(output.token.lowercased)"
          "user": {
            "id": "\(output.userId.lowercased)"
            "name": "\(output.userName)"
          }
        },
        "device": {
          "id": "\(output.deviceId.lowercased)"
        }
      }
    }
    """
    return .init(graphqlData: json)
  }

  static func createSuspendFilterRequest(_ request: Request) async throws -> Response {
    struct Input: PairInput {
      var duration: Int
      var requestComment: String?
    }
    let input = try request.content.decode(Input.self)
    _ = try await CreateSuspendFilterRequest.resolve(
      with: .init(duration: input.duration, comment: input.requestComment),
      in: try await context(request)
    )
    let json = """
    { "request": { "id": "deadbeef-dead-beef-dead-deadbeefdead" } }
    """
    return .init(graphqlData: json)
  }
}

// extensions

extension LegacyMacAppGraphQLRoute {
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
    return .init(requestId: request.id, user: user, token: userToken)
  }
}

private extension UUID {
  init?(authorizationHeader: String) {
    let prefix = "Bearer "
    guard authorizationHeader.hasPrefix(prefix) else { return nil }
    self.init(uuidString: String(authorizationHeader.dropFirst(prefix.count)))
  }
}
