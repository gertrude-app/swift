import DuetSQL
import Gertie
import Vapor
import XCore

enum StripeEventsRoute {
  static func handler(_ request: Request) async throws -> Response {
    guard let json = try await request.collectedBody() else {
      return Response(status: .badRequest)
    }

    let stripeEvent = try await Current.db.create(StripeEvent(json: json))
    let event = try? JSON.decode(json, as: EventInfo.self)
    if event?.type == "invoice.paid",
       let email = event?.data?.object?.customer_email {

      let admin = try? await Admin.query()
        .where(.email == email.lowercased())
        .first()

      if let admin {
        admin.subscriptionStatus = .paid
        admin.subscriptionStatusExpiration = event?.data?.object?.period_end
          .map { Date(timeIntervalSince1970: TimeInterval($0)).advanced(by: .days(2)) }
          ?? Current.date().advanced(by: .days(33))
        if admin.subscriptionId == nil {
          unexpected("d63aab05", admin.id, "event: \(stripeEvent.id)")
        }
      } else {
        unexpected("b3aaf12c", detail: "email: \(email), event: \(stripeEvent.id)")
      }
    }

    Task {
      await Current.slack.sysLog("""
        *Received Gertrude Stripe Event:*
        - type: `\(event?.type ?? "(nil)")`
        - customer email: `\(event?.data?.object?.customer_email ?? "(nil)")`
      """)
    }

    return Response(status: .noContent)
  }
}

private struct EventInfo: Decodable {
  struct Data: Decodable {
    struct InvoiceObject: Decodable {
      var customer_email: String?
      var period_end: Int?
    }

    var object: InvoiceObject?
  }

  var type: String?
  var data: Data?
}
