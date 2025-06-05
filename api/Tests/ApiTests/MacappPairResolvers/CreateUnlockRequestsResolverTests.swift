import Dependencies
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class CreateUnlockRequestsResolverTests: ApiTestCase, @unchecked Sendable {
  func testCreateUnlockRequests_v3() async throws {
    let child = try await self.childWithComputer()
    let blocked = CreateUnlockRequests_v3.Input.BlockedRequest(
      bundleId: "com.example.app",
      url: "https://example.com"
    )
    let blocked2 = CreateUnlockRequests_v3.Input.BlockedRequest(
      bundleId: "com.other.thing",
      url: "https://foo.com"
    )

    let uuids = MockUUIDs()
    let output = try await withDependencies {
      $0.uuid = .mock(uuids)
    } operation: {
      try await CreateUnlockRequests_v3.resolve(
        with: .init(blockedRequests: [blocked, blocked2], comment: nil),
        in: self.context(child)
      )
    }

    expect(output).toEqual([uuids[0], uuids[1]])

    let unlockReq1 = try await self.db.find(UnlockRequest.Id(uuids[0]))
    expect(unlockReq1.requestComment).toEqual(nil)
    expect(unlockReq1.appBundleId).toEqual("com.example.app")
    expect(unlockReq1.url).toEqual("https://example.com")
    expect(unlockReq1.computerUserId).toEqual(child.computerUser.id)
    expect(unlockReq1.status).toEqual(.pending)

    let unlockReq2 = try await self.db.find(UnlockRequest.Id(uuids[1]))
    expect(unlockReq2.requestComment).toEqual(nil)
    expect(unlockReq2.appBundleId).toEqual("com.other.thing")
    expect(unlockReq2.url).toEqual("https://foo.com")
    expect(unlockReq2.computerUserId).toEqual(child.computerUser.id)
    expect(unlockReq2.status).toEqual(.pending)

    expect(sent.parentNotifications).toEqual([.init(
      parentId: child.parentId,
      event: .unlockRequestSubmitted(.init(
        dashboardUrl: "",
        userId: child.id,
        userName: child.name,
        requestIds: [unlockReq1.id, unlockReq2.id]
      ))
    )])
  }
}
