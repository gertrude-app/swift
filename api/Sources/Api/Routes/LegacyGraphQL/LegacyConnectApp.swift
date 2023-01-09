import MacAppRoute
import Vapor
import XCore

extension LegacyMacAppGraphQLRoute {
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
}
