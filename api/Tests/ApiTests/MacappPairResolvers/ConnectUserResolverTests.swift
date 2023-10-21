import DuetSQL
import MacAppRoute
import XCore
import XCTest
import XExpect

@testable import Api

final class ConnectUserResolversTests: ApiTestCase {

  func testConnectUser_createNewDevice() async throws {
    let user = try await Entities.user()
    let code = await Current.ephemeral.createPendingAppConnection(user.id)

    let input = input(code)
    let userData = try await ConnectUser.resolve(with: input, in: context)

    expect(userData.id).toEqual(user.id.rawValue)
    expect(userData.name).toEqual(user.name)

    let userDevice = try await Current.db.find(UserDevice.Id(userData.deviceId))
    let device = try await Current.db.find(userDevice.deviceId)

    expect(userDevice.username).toEqual(input.username)
    expect(userDevice.fullUsername).toEqual(input.fullUsername)
    expect(userDevice.numericId).toEqual(input.numericId)
    expect(userDevice.appVersion).toEqual(input.appVersion)
    expect(device.serialNumber).toEqual(input.serialNumber)
    expect(device.modelIdentifier).toEqual(input.modelIdentifier)

    let token = try await Current.db.query(UserToken.self)
      .where(.value == userData.token)
      .first()

    expect(token.userId).toEqual(user.id)
  }

  func testConnectUser_twoUsersSameComputer() async throws {
    Current.verificationCode = .live
    try await Device.deleteAll()
    let user1 = try await Entities.user()
    let code1 = await Current.ephemeral.createPendingAppConnection(user1.id)

    let user2 = try await Entities.user { $0.adminId = user1.admin.id }
    let code2 = await Current.ephemeral.createPendingAppConnection(user2.id)

    var input1 = input(code1)
    input1.numericId = 501
    _ = try await ConnectUser.resolve(with: input1, in: context)

    var input2 = input(code2)
    input2.numericId = 502 // <-- same computer, different user
    // should not throw...
    _ = try await ConnectUser.resolve(with: input2, in: context)
  }

  func testConnectUser_verificationCodeNotFound() async throws {
    try await expectErrorFrom { [self] in
      let input = self.input(123)
      _ = try await ConnectUser.resolve(with: input, in: self.context)
    }.toContain("verification code not found")
  }

  // re-connect from a macOS user that has had gertrude installed before
  func testConnectUser_ReassignToDifferentUserOwnedBySameAdmin() async throws {
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

    let userData = try await ConnectUser.resolve(with: input, in: context)

    expect(userData.id).toEqual(newUser.id.rawValue)
    expect(userData.name).toEqual(newUser.name)

    let retrievedDevice = try await Current.db.find(existingUser.device.id)
    expect(retrievedDevice.userId).toEqual(newUser.model.id)

    let retrievedOldToken = try? await Current.db.find(existingUserToken.id)
    XCTAssertNil(retrievedOldToken)
  }

  // test sanity check, computer/user registered to a different admin
  func testConnectUser_ExistingDeviceToDifferentUser_FailsIfDifferentAdmin() async throws {
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
      _ = try await ConnectUser.resolve(with: input, in: self.context)
    }.toContain("associated with another Gertrude parent account")

    // old token is not deleted
    let retrievedOldToken = try? await Current.db.find(existingUserToken.id)
    XCTAssertNotNil(retrievedOldToken)
  }

  func testPre2_0_4AppSendingHostnameForConnectStillDecodes() {
    let json = """
    {
      "verificationCode": 123,
      "appVersion": "1.0.0",
      "hostname": "kids-macbook-air",
      "modelIdentifier": "MacBookAir7,1",
      "username": "kids",
      "fullUsername": "kids",
      "numericId": 501,
      "serialNumber": "X02VH0Y6JG5J"
    }
    """
    let input = try? JSON.decode(json, as: ConnectUser.Input.self)
    expect(input).not.toBeNil()
  }

  // helpers

  func input(_ code: Int) -> ConnectUser.Input {
    ConnectUser.Input(
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
