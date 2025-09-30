import XCTest
import XCTVapor
import XExpect

@testable import Api

final class StripeEventTests: ApiTestCase, @unchecked Sendable {
  func testSetsSubscriptionId() async throws {
    let subscriptionId: Parent.SubscriptionId = .init("subId_".random)
    let parent = try await self.db.create(Parent.random(with: { $0.subscriptionId = nil }))

    let json = """
      {
        "type": "invoice.paid",
        "data": {
          "object": {
            "customer_email": "\(parent.email)",
            "subscription": "\(subscriptionId.rawValue)",
          }
        }
      }
    """

    try await app.test(.POST, "stripe-events", body: .init(string: json), afterResponse: { res in
      let retrieved = try await self.db.find(parent.id)
      expect(retrieved.subscriptionId).toEqual(subscriptionId)
    })
  }

  func testUpdateAdminSubscriptionStatusExpirationFromStripeEvent() async throws {
    let periodEnd = 1_704_050_627
    let parent = try await self.db.create(
      Parent.random(with: { $0.subscriptionStatusExpiration = .reference - .days(1000) })
    )

    let json = """
      {
        "type": "invoice.paid",
        "data": {
          "object": {
            "customer_email": "\(parent.email)",
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
      let retrieved = try await self.db.find(parent.id)
      expect(retrieved.subscriptionStatusExpiration).toEqual(expectedNewStatusExpiration)
    })
  }

  func testUpdateAdminSubscriptionStatusFromSubscriptionIdAndWrongEmail() async throws {
    let periodEnd = 1_704_050_627
    let parent = try await self.db.create(
      Parent.random(with: {
        $0.email = "changed@email.com" // <-- different email from stripe customer_email
        $0.subscriptionId = .init("subId_".random)
        $0.subscriptionStatusExpiration = .reference - .days(1000)
      })
    )

    let json = """
      {
        "type": "invoice.paid",
        "data": {
          "object": {
            "customer_email": "stripe@email.com",
            "subscription": "\(parent.subscriptionId!.rawValue)",
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
      let retrieved = try await self.db.find(parent.id)
      expect(retrieved.subscriptionStatusExpiration).toEqual(expectedNewStatusExpiration)
    })
  }
}
