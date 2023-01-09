import MacAppRoute
import Vapor
import XCore

extension LegacyMacAppGraphQLRoute {

  private struct Key: Encodable {
    let jsonString: String
  }

  private struct KeyRecord: Encodable {
    let id: String
    let key: Key
  }

  static func appInstructions(_ request: Request) async throws -> Response {
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
}
