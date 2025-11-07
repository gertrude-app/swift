import Dependencies
import IOSRoute
import XCTest
import XExpect

@testable import Api

final class ConnectDeviceResolverTests: ApiTestCase, @unchecked Sendable {
  func testConnectIOSDeviceHappyPath() async throws {
    let child = try await self.child()
    let data = try await withDependencies {
      $0.verificationCode = .liveValue
      $0.uuid = .incrementing
    } operation: {
      let code = await with(dependency: \.ephemeral)
        .createPendingAppConnection(child.id)
      return try await ConnectDevice_b1.resolve(
        with: .init(
          verificationCode: code,
          vendorId: .init(),
          deviceType: "iPhone",
          appVersion: "1.5.0",
          iosVersion: "18.4.0",
        ),
        in: .mock,
      )
    }

    expect(data).toEqual(.init(
      childId: child.id.rawValue,
      token: .init(2),
      deviceId: .init(0),
      childName: child.name,
    ))
  }
}
