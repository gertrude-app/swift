import IOSRoute
import XCTest
import XExpect

@testable import Api

final class IOSFilterSuspensionResolversTests: ApiTestCase, @unchecked Sendable {
  func testCreateSuspendFilterRequest() async throws {
    let child = try await self.childWithIOSDevice()
    let reqId = try await CreateSuspendFilterRequest.resolve(
      with: .init(duration: .init(33)),
      in: child.context
    )

    let retrieved = try await self.db.find(IOSApp.SuspendFilterRequest.Id(reqId))
    expect(retrieved.duration).toEqual(.init(33))

    expect(self.sent.parentNotifications).toEqual([
      .init(
        parentId: child.parentId,
        event: .suspendFilterRequestSubmitted(.init(
          dashboardUrl: "",
          childId: child.id,
          childName: child.name,
          duration: 33,
          requestComment: nil,
          context: .iosapp(deviceId: child.device.id, requestId: .init(reqId))
        ))
      ),
    ])
  }

  func testPollForDecision() async throws {
    let child = try await self.childWithIOSDevice()
    var request = try await self.db.create(IOSApp.SuspendFilterRequest(
      deviceId: child.device.id,
      status: .pending,
      duration: .init(99)
    ))

    var status = try await PollFilterSuspensionDecision.resolve(
      with: request.id.rawValue,
      in: child.context
    )
    expect(status).toEqual(.pending)

    request.status = .accepted
    try await self.db.update(request)
    status = try await PollFilterSuspensionDecision.resolve(
      with: request.id.rawValue,
      in: child.context
    )
    expect(status).toEqual(.accepted(duration: 99, parentComment: nil))
  }
}
