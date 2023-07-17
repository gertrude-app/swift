import DuetSQL
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class ConnectAppResolversTests: ApiTestCase {

  func testConnectApp_createNewDevice() async throws {
    let user = try await Entities.user()
    let code = await Current.ephemeral.createPendingAppConnection(user.id)

    let input = input(code)
    let output = try await ConnectApp.resolve(with: input, in: context)

    expect(output.userId).toEqual(user.id.rawValue)
    expect(output.userName).toEqual(user.name)

    let userDevice = try await Current.db.find(UserDevice.Id(output.deviceId))
    let device = try await Current.db.find(userDevice.deviceId)

    expect(userDevice.username).toEqual(input.username)
    expect(userDevice.fullUsername).toEqual(input.fullUsername)
    expect(userDevice.numericId).toEqual(input.numericId)
    expect(userDevice.appVersion).toEqual(input.appVersion)
    expect(device.serialNumber).toEqual(input.serialNumber)
    expect(device.modelIdentifier).toEqual(input.modelIdentifier)

    let token = try await Current.db.query(UserToken.self)
      .where(.value == output.token)
      .first()

    expect(token.userId).toEqual(user.id)
  }

  func testConnectDevice_verificationCodeNotFound() async throws {
    try await expectErrorFrom { [self] in
      let input = self.input(123)
      _ = try await ConnectApp.resolve(with: input, in: self.context)
    }.toContain("verification code not found")
  }

  // re-connect from a macOS user that has had gertrude installed before
  func testConnectDevice_ReassignToDifferentUserOwnedBySameAdmin() async throws {
    let existingUser = try await Entities.user().withDevice()
    let existingUserToken = try await Current.db.create(UserToken(
      userId: existingUser.id,
      userDeviceId: existingUser.device.id
    ))

    // different user, owned by same admin
    let newUser = try await Entities.user { $0.adminId = existingUser.admin.id }
    Current.verificationCode = .live
    let code = await Current.ephemeral.createPendingAppConnection(newUser.model.id)

    // happy path, the device exists, registered to another user, but that's OK
    // because the same admin owns both users, so switch it over
    newUser.model.adminId = existingUser.admin.model.id
    try await Current.db.update(newUser.model)

    var input = input(code)
    input.numericId = existingUser.device.numericId
    input.serialNumber = existingUser.adminDevice.serialNumber

    let output = try await ConnectApp.resolve(with: input, in: context)

    expect(output.userId).toEqual(newUser.id.rawValue)
    expect(output.userName).toEqual(newUser.name)

    let retrievedDevice = try await Current.db.find(existingUser.device.id)
    expect(retrievedDevice.userId).toEqual(newUser.model.id)

    let retrievedOldToken = try? await Current.db.find(existingUserToken.id)
    XCTAssertNil(retrievedOldToken)
  }

  // test sanity check, computer/user registered to a different admin
  func testConnectDevice_ExistingDeviceToDifferentUser_FailsIfDifferentAdmin() async throws {
    let existingUser = try await Entities.user().withDevice()
    let existingUserToken = try await Current.db.create(UserToken(
      userId: existingUser.model.id,
      userDeviceId: existingUser.device.id
    ))

    // // this user is from a DIFFERENT admin, so it should fail
    let newUser = try await Entities.user()
    Current.verificationCode = .live
    let code = await Current.ephemeral.createPendingAppConnection(newUser.model.id)

    var input = input(code)
    input.numericId = existingUser.device.numericId
    input.serialNumber = existingUser.adminDevice.serialNumber

    try await expectErrorFrom { [self] in
      _ = try await ConnectApp.resolve(with: input, in: self.context)
    }.toContain("registered to another admin")

    // old token is not deleted
    let retrievedOldToken = try? await Current.db.find(existingUserToken.id)
    XCTAssertNotNil(retrievedOldToken)
  }

  // helpers

  func input(_ code: Int) -> ConnectApp.Input {
    ConnectApp.Input(
      verificationCode: code,
      appVersion: "1.0.0",
      modelIdentifier: "MacBookAir7,1",
      username: "kids",
      fullUsername: "kids",
      numericId: 501,
      serialNumber: "X02VH0Y6JG5J"
    )
  }

  var context: Context {
    .init(requestId: "", dashboardUrl: "")
  }
}
