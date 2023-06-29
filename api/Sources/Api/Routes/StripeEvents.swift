import DuetSQL
import Gertie
import Vapor
import XCore

enum StripeEventsRoute {
  static func handler(_ request: Request) async throws -> Response {
    guard let json = try await request.collectedBody() else {
      return Response(status: .badRequest)
    }

    try await Current.db.create(StripeEvent(json: json))

    Task {
      let eventInfo = try? JSON.decode(json, as: EventInfo.self)
      await Current.slack.sysLog("""
        *Received Gertrude Stripe Event:*
        - type: `\(eventInfo?.type ?? "(nil)")`
        - customer email: `\(eventInfo?.data?.object?.customer_email ?? "(nil)")`
      """)
    }

    return Response(status: .noContent)
  }
}

private struct EventInfo: Decodable {
  struct Data: Decodable {
    struct Object: Decodable {
      var customer_email: String?
    }

    var object: Object?
  }

  var type: String?
  var data: Data?
}
