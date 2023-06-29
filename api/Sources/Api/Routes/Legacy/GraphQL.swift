import DuetSQL
import MacAppRoute
import Gertie
import Vapor
import XCore

enum LegacyMacAppGraphQLRoute {
  static func handler(_ request: Request) async throws -> Response {
    do {
      let operationName = try request.content.decode(Name.self).operationName
      Current.logger.notice("Legacy GraphQL operation: \(operationName.red)")
      switch operationName {
      case "AccountStatus":
        return try await accountStatus(request)
      case "AppInstructions":
        return try await appInstructions(request)
      case "ConnectApp":
        return try await connectApp(request)
      case "CreateSuspendFilterRequest":
        return try await createSuspendFilterRequest(request)
      case "InsertKeystrokeLines":
        return try await insertKeystrokeLines(request)
      case "InsertNetworkDecisions":
        return try await insertNetworkDecisions(request)
      case "CreateUnlockRequests":
        return try await createUnlockRequests(request)
      case "CreateSignedScreenshotUpload":
        return try await createSignedScreenshotUpload(request)
      default:
        throw Abort(.notFound, reason: "Unknown operation: \(operationName)")
      }
    } catch {
      Current.logger.error("Legacy GraphQL error: \(error)")
      let message = "\(error)".replacingOccurrences(of: "\"", with: "'")
      return .init(
        headers: ["Content-Type": "application/json"],
        body: .init(string: #"{"errors":[{"message":"\#(message)"}]}")"#)
      )
    }
  }

  static func edensHandler(_ request: Request) async throws -> Response {
    do {
      let operationName = try request.content.decode(Name.self).operationName
      switch operationName {
      case "CreateSignedScreenshotUpload":
        return try await createSignedScreenshotUpload(request)
      case "InsertKeystrokeLines":
        return try await insertKeystrokeLines(request)
      case "RefreshRules": // Eden only
        return try await refreshRules(request)
      default:
        throw Abort(.notFound, reason: "Unknown operation: \(operationName)")
      }
    } catch {
      let message = "\(error)".replacingOccurrences(of: "\"", with: "'")
      return .init(
        headers: ["Content-Type": "application/json"],
        body: .init(string: #"{"errors":[{"message":"\#(message)"}]}")"#)
      )
    }
  }

  // implementations

  static func accountStatus(_ request: Request) async throws -> Response {
    let context = try await context(request)
    let output = try await GetAccountStatus.resolve(in: context)
    let json = """
    {
      "user": {
        "__typename": "User",
        "admin": {
          "__typename": "Admin",
          "accountStatus": "\(output.status)"
        }
      }
    }
    """
    return .init(graphqlData: json)
  }

  struct Manifest: Encodable {
    var __typename = "AppIdManifest"
    let jsonString: String
  }

  static func appInstructions(_ request: Request) async throws -> Response {
    struct Key: Encodable {
      var __typename = "Key"
      let jsonString: String
    }
    struct KeyRecord: Encodable {
      var __typename = "KeyRecord"
      let id: String
      let key: Key
    }

    let appVersion = request.headers.first(name: .xAppVersion) ?? ""
    let context = try await context(request)
    let output = try await RefreshRules.resolve(
      with: .init(appVersion: appVersion),
      in: context
    )
    let records = try output.keys.map { key in
      KeyRecord(
        id: key.id.lowercased,
        key: .init(jsonString: try JSON.encode(key.key))
      )
    }

    let json = """
    {
      "user": {
        "__typename": "User",
        "keyloggingEnabled": \(output.keyloggingEnabled),
        "screenshotsEnabled": \(output.screenshotsEnabled),
        "screenshotsFrequency": \(output.screenshotsFrequency),
        "screenshotsResolution": \(output.screenshotsResolution),
        "keychains": [{ "__typename": "Keychain", "keyRecords": \(try JSON.encode(records)) }]
      },
      "manifest": \(try JSON.encode(Manifest(jsonString: try JSON.encode(output.appManifest))))
    }
    """
    return .init(graphqlData: json)
  }

  // only used by Eden
  static func refreshRules(_ request: Request) async throws -> Response {
    let user = try await context(request).user
    let json = """
    {
      "guardian": {
        "__typename": "Guardian",
        "keyloggingEnabled": \(user.keyloggingEnabled),
        "screenshotsEnabled": \(user.screenshotsEnabled),
        "screenshotsFrequency": \(user.screenshotsFrequency),
        "screenshotsResolution": \(user.screenshotsResolution),
        "keychains": []
      },
      "manifest": \(try JSON.encode(Manifest(jsonString: try JSON.encode(AppIdManifest()))))
    }
    """
    return .init(graphqlData: json)
  }

  static func connectApp(_ request: Request) async throws -> Response {
    let input = try request.content.decode(Vars<ConnectApp.Input>.self).variables
    let output = try await ConnectApp.resolve(
      with: input,
      in: .init(requestId: request.id, dashboardUrl: "")
    )
    let json = """
    {
      "connection": {
        "__typename": "AppConnection",
        "token": {
          "__typename": "UserToken",
          "value": "\(output.token.lowercased)",
          "user": {
            "__typename": "User",
            "id": "\(output.userId.lowercased)",
            "name": "\(output.userName)"
          }
        },
        "device": {
          "__typename": "Device",
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
    let input = try request.content.decode(Vars<Input>.self).variables
    _ = try await CreateSuspendFilterRequest.resolve(
      with: .init(duration: input.duration, comment: input.requestComment),
      in: try await context(request)
    )
    let json = """
    {
      "request": {
        "__typename": "SuspendFilterRequest",
        "id": "deadbeef-dead-beef-dead-deadbeefdead"
      }
    }
    """
    return .init(graphqlData: json)
  }

  static func insertNetworkDecisions(_ request: Request) async throws -> Response {
    let input = try request.content.decode(Vars<Input<[LegacyNetworkDecisionInput]>>.self)
    _ = try await CreateNetworkDecisions.resolve(
      with: input.variables.input.map { .init(from: $0) },
      in: try await context(request)
    )
    return .init(graphqlData: #"{"decisions":[]}"#)
  }

  static func insertKeystrokeLines(_ request: Request) async throws -> Response {
    let input = try request.content.decode(Vars<Input<[LegacyKeystrokeLineInput]>>.self)
    _ = try await CreateKeystrokeLines.resolve(
      with: input.variables.input.map { .init(from: $0) },
      in: try await context(request)
    )
    return .init(graphqlData: #"{"lines":[]}"#)
  }

  static func createUnlockRequests(_ request: Request) async throws -> Response {
    let input = try request.content.decode(Vars<Input<CreateUnlockRequests.Input>>.self).variables
    _ = try await CreateUnlockRequests.resolve(with: input.input, in: try await context(request))
    return .init(graphqlData: #"{"requests":[]}"#)
  }

  static func createSignedScreenshotUpload(_ request: Request) async throws -> Response {
    let input = try request.content.decode(Vars<CreateSignedScreenshotUpload.Input>.self)
    let output = try await CreateSignedScreenshotUpload.resolve(
      with: input.variables,
      in: try await context(request)
    )
    let json = """
    {
      "urls": {
        "__typename": "SignedScreenshotUpload",
        "uploadUrl": "\(output.uploadUrl.absoluteString)",
        "webUrl": "\(output.webUrl.absoluteString)"
      }
    }
    """
    return .init(graphqlData: json)
  }
}

// decoding types

private struct Name: Decodable {
  let operationName: String
}

private struct Vars<T: Decodable>: Decodable {
  var variables: T
}

private struct Input<T: Decodable>: Decodable {
  var input: T
}

// helpers

private struct LegacyKeystrokeLineInput: PairInput {
  var appName: String
  var line: String
  var time: Int
}

private extension CreateKeystrokeLines.KeystrokeLineInput {
  init(from legacy: LegacyKeystrokeLineInput) {
    self.init(
      appName: legacy.appName,
      line: legacy.line,
      time: Date(timeIntervalSince1970: TimeInterval(legacy.time))
    )
  }
}

private struct LegacyNetworkDecisionInput: Decodable {
  var id: UUID?
  var verdict: NetworkDecisionVerdict
  var reason: NetworkDecisionReason
  var ipProtocolNumber: Int?
  var responsibleKeyId: UUID?
  var userId: Int?
  var hostname: String?
  var url: String?
  var ipAddress: String?
  var appBundleId: String?
  var time: Int
  var count: Int
}

private extension CreateNetworkDecisions.DecisionInput {
  init(from legacy: LegacyNetworkDecisionInput) {
    self.init(
      id: legacy.id,
      verdict: legacy.verdict,
      reason: legacy.reason,
      ipProtocolNumber: legacy.ipProtocolNumber,
      responsibleKeyId: legacy.responsibleKeyId,
      hostname: legacy.hostname,
      url: legacy.url,
      ipAddress: legacy.ipAddress,
      appBundleId: legacy.appBundleId,
      time: Date(timeIntervalSince1970: TimeInterval(legacy.time)),
      count: legacy.count
    )
  }
}

// extensions

extension LegacyMacAppGraphQLRoute {
  static func context(_ request: Request) async throws -> UserContext {
    let dashboardUrl = request.headers.first(name: .xDashboardUrl) ?? Env.DASHBOARD_URL
    let userToken = try await request.userToken()
    let user = try await Current.db.find(userToken.userId)
    return .init(requestId: request.id, dashboardUrl: dashboardUrl, user: user, token: userToken)
  }
}

extension Response {
  convenience init(graphqlData json: String) {
    self.init(
      headers: ["Content-Type": "application/json"],
      body: .init(string: #"{"data":\#(json)}"#)
    )
  }
}
