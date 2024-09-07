import XCTest
import XCTVapor
import XExpect

@testable import Api

final class StripeEventTests: ApiTestCase {
  func testSetsSubscriptionId() async throws {
    let admin = try await self.db.create(
      Admin.random(with: { $0.subscriptionId = nil })
    )

    let json = """
      {
        "type": "invoice.paid",
        "data": {
          "object": {
            "customer_email": "\(admin.email)",
            "subscription": "sub_123"
          }
        }
      }
    """

    try await app.test(.POST, "stripe-events", body: .init(string: json), afterResponse: { res in
      let retrieved = try await self.db.find(admin.id)
      expect(retrieved.subscriptionId).toEqual("sub_123")
    })
  }

  func testUpdateAdminSubscriptionStatusExpirationFromStripeEvent() async throws {
    let periodEnd = 1_704_050_627
    let admin = try await self.db.create(
      Admin.random(with: { $0.subscriptionStatusExpiration = .distantPast })
    )

    let json = """
      {
        "type": "invoice.paid",
        "data": {
          "object": {
            "customer_email": "\(admin.email)",
            "lines": {
              "data": [
                {
                  "period": {
                    "end": \(periodEnd),
                    "start": 1701372227
                  }
                }
              ]
            }
          }
        }
      }
    """

    let expectedNewStatusExpiration = Date(timeIntervalSince1970: TimeInterval(periodEnd))
      .advanced(by: .days(2))

    try await app.test(.POST, "stripe-events", body: .init(string: json), afterResponse: { res in
      expect(res.status).toEqual(.noContent)
      let retrieved = try await self.db.find(admin.id)
      expect(retrieved.subscriptionStatusExpiration).toEqual(expectedNewStatusExpiration)
    })
  }
}
