import Dependencies
import DuetSQL
import Gertie
import Vapor
import XCore

enum StripeEventsRoute {
  @Sendable static func handler(_ request: Request) async throws -> Response {
    guard let json = try await request.collectedBody() else {
      return Response(status: .badRequest)
    }

    let stripeEvent = try await request.context.db.create(StripeEvent(json: json))
    let event = try? JSON.decode(json, as: EventInfo.self)

    if event?.type == "invoice.paid",
       let email = event?.data?.object?.customer_email {

      let admin = try? await Admin.query()
        .where(.email == email.lowercased())
        .first(in: request.context.db)

      if var admin {
        admin.subscriptionStatus = .paid
        admin.subscriptionStatusExpiration = event?.data?.object?.lines?.data?.first?.period?.end
          .map { Date(timeIntervalSince1970: TimeInterval($0)).advanced(by: .days(2)) }
          ?? Current.date().advanced(by: .days(33))

        switch (admin.subscriptionId, event?.data?.object?.subscription) {
        case (.none, .some(let subscriptionId)):
          admin.subscriptionId = .init(rawValue: subscriptionId)
          Task { await Current.slack.sysLog("*FIRST Payment* from `\(email)`") }
        case (.some(let existing), .some(let subscriptionId))
          where existing.rawValue != subscriptionId:
          admin.subscriptionId = .init(rawValue: subscriptionId)
          unexpected("2156b9f8", detail: "prev: \(existing), new: \(subscriptionId)")
        default:
          break
        }
        try await request.context.db.update(admin)
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
    struct Object: Decodable {
      struct Lines: Decodable {
        struct Line: Decodable {
          struct Period: Decodable {
            var end: Int?
          }

          var period: Period?
        }

        var data: [Line]?
      }

      var customer_email: String?
      var lines: Lines?
      var subscription: String?
    }

    var object: Object?
  }

  var type: String?
  var data: Data?
}
