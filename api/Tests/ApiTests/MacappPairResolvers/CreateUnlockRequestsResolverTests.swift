import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class CreateUnlockRequestsResolverTests: ApiTestCase {
  func testCreateUnlockRequests_v3() async throws {
    let user = try await Entities.user().withDevice()
    let blocked = CreateUnlockRequests_v3.Input.BlockedRequest(
      bundleId: "com.example.app",
      url: "https://example.com"
    )
    let blocked2 = CreateUnlockRequests_v3.Input.BlockedRequest(
      bundleId: "com.other.thing",
      url: "https://foo.com"
    )

    let (uuid1, uuid2) = mockUUIDs()

    let output = try await CreateUnlockRequests_v3.resolve(
      with: .init(blockedRequests: [blocked, blocked2], comment: nil),
      in: self.context(user)
    )

    expect(output).toEqual([uuid1, uuid2])

    let unlockReq1 = try await UnlockRequest.find(.init(uuid1))
    expect(unlockReq1.requestComment).toEqual(nil)
    expect(unlockReq1.appBundleId).toEqual("com.example.app")
    expect(unlockReq1.url).toEqual("https://example.com")
    expect(unlockReq1.userDeviceId).toEqual(user.device.id)
    expect(unlockReq1.status).toEqual(.pending)

    let unlockReq2 = try await UnlockRequest.find(.init(uuid2))
    expect(unlockReq2.requestComment).toEqual(nil)
    expect(unlockReq2.appBundleId).toEqual("com.other.thing")
    expect(unlockReq2.url).toEqual("https://foo.com")
    expect(unlockReq2.userDeviceId).toEqual(user.device.id)
    expect(unlockReq2.status).toEqual(.pending)

    expect(sent.adminNotifications).toEqual([.init(
      adminId: user.adminId,
      event: .unlockRequestSubmitted(.init(
        dashboardUrl: "",
        userId: user.id,
        userName: user.name,
        requestIds: [unlockReq1.id, unlockReq2.id]
      ))
    )])
  }

  func testCreateUnlockRequests_v2() async throws {
    let user = try await Entities.user().withDevice()
    let blocked = CreateUnlockRequests_v2.Input.BlockedRequest(
      bundleId: "com.example.app",
      url: "https://example.com"
    )

    let (uuid, _) = mockUUIDs()

    let output = try await CreateUnlockRequests_v2.resolve(
      with: .init(blockedRequests: [blocked], comment: "please dad!"),
      in: self.context(user)
    )

    expect(output).toEqual(.success)

    let unlockReq = try await UnlockRequest.find(.init(uuid))
    expect(unlockReq.requestComment).toEqual("please dad!")
    expect(unlockReq.appBundleId).toEqual("com.example.app")
    expect(unlockReq.url).toEqual("https://example.com")
    expect(unlockReq.userDeviceId).toEqual(user.device.id)
    expect(unlockReq.status).toEqual(.pending)

    expect(sent.adminNotifications).toEqual([.init(
      adminId: user.adminId,
      event: .unlockRequestSubmitted(.init(
        dashboardUrl: "",
        userId: user.id,
        userName: user.name,
        requestIds: [unlockReq.id]
      ))
    )])
  }
}
