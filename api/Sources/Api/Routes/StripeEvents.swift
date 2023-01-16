import DuetSQL
import Shared
import Vapor

enum StripeEventsRoute {
  static func handler(_ request: Request) async throws -> Response {
    guard let json = try await request.collectedBody() else {
      return Response(status: .badRequest)
    }

    Current.sendGrid.fireAndForget(.toJared(
      "Gertrude App received stripe event",
      "<pre>\(json)</pre>"
    ))

    try await Current.db.create(StripeEvent(json: json))

    return Response(status: .noContent)
  }
}
