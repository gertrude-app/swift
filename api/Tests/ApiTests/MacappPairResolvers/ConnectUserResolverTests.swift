import Dependencies
import DuetSQL
import Gertie
import MacAppRoute
import XCore
import XCTest
import XExpect

@testable import Api

final class ConnectUserResolversTests: ApiTestCase {
  override func invokeTest() {
    withDependencies {
      $0.verificationCode = .liveValue
    } operation: {
      super.invokeTest()
    }
  }

  func testConnectUser_createNewDevice() async throws {
    let user = try await self.user()
    let code = await Current.ephemeral.createPendingAppConnection(user.id)

    let input = input(code)
    let userData = try await ConnectUser.resolve(with: input, in: self.context)

    expect(userData.id).toEqual(user.id.rawValue)
    expect(userData.name).toEqual(user.name)

    let userDevice = try await self.db.find(UserDevice.Id(userData.deviceId))
    let device = try await self.db.find(userDevice.deviceId)

    expect(userDevice.username).toEqual(input.username)
    expect(userDevice.fullUsername).toEqual(input.fullUsername)
    expect(userDevice.numericId).toEqual(input.numericId)
    expect(userDevice.appVersion).toEqual(input.appVersion)
    expect(userDevice.isAdmin).toEqual(input.isAdmin)
    expect(device.serialNumber).toEqual(input.serialNumber)
    expect(device.modelIdentifier).toEqual(input.modelIdentifier)
    expect(device.osVersion).toEqual(Semver("14.2.0"))

    let token = try await UserToken.query()
      .where(.value == userData.token)
      .first(in: self.db)

    expect(token.userId).toEqual(user.id)
  }

  func testConnectUser_twoUsersSameComputer() async throws {
    try await self.db.delete(all: Device.self)
    let user1 = try await self.user()
    let code1 = await Current.ephemeral.createPendingAppConnection(user1.id)

    let user2 = try await self.user { $0.adminId = user1.admin.id }
    let code2 = await Current.ephemeral.createPendingAppConnection(user2.id)

    var input1 = self.input(code1)
    input1.numericId = 501

    _ = try await ConnectUser.resolve(with: input1, in: self.context)

    var input2 = self.input(code2)
    input2.numericId = 502 // <-- same computer, different user
    // should not throw...
    _ = try await ConnectUser.resolve(with: input2, in: self.context)
  }

  func testConnectUser_verificationCodeNotFound() async throws {
    try await expectErrorFrom { [self] in
      let input = self.input(123)
      _ = try await ConnectUser.resolve(with: input, in: self.context)
    }.toContain("verification code not found")
  }

  // re-connect from a macOS user that has had gertrude installed before
  func testConnectUser_ReassignToDifferentUserOwnedBySameAdmin() async throws {
    try await withDependencies {
      $0.date = .init { Date() } // for token expiration
    } operation: {
      let existingUser = try await self.userWithDevice()
      let existingUserToken = try await self.db.create(UserToken(
        userId: existingUser.id,
        userDeviceId: existingUser.device.id
      ))

      // different user, owned by same admin
      let newUser = try await self.user(with: \.adminId, of: existingUser.admin.id)
      let code = await Current.ephemeral.createPendingAppConnection(newUser.model.id)

      // happy path, the device exists, registered to another user, but that's OK
      // because the same admin owns both users, so switch it over
      newUser.model.adminId = existingUser.admin.model.id
      try await self.db.update(newUser.model)

      var input = input(code)
      input.numericId = existingUser.device.numericId
      input.serialNumber = existingUser.adminDevice.serialNumber
      let userData = try await ConnectUser.resolve(with: input, in: self.context)

      expect(userData.id).toEqual(newUser.id.rawValue)
      expect(userData.name).toEqual(newUser.name)

      let retrievedDevice = try await self.db.find(existingUser.device.id)
      expect(retrievedDevice.userId).toEqual(newUser.model.id)

      let retrievedOldToken = try await self.db.find(existingUserToken.id)
      expect(retrievedOldToken.deletedAt).not.toBeNil()
    }
  }

  // test sanity check, computer/user registered to a different admin
  func testConnectUser_ExistingDeviceToDifferentUser_FailsIfDifferentAdmin() async throws {
    let existingUser = try await self.userWithDevice()
    let existingUserToken = try await self.db.create(UserToken(
      userId: existingUser.model.id,
      userDeviceId: existingUser.device.id
    ))

    // // this user is from a DIFFERENT admin, so it should fail
    let newUser = try await self.user()
    let code = await Current.ephemeral.createPendingAppConnection(newUser.model.id)

    var input = input(code)
    input.numericId = existingUser.device.numericId
    input.serialNumber = existingUser.adminDevice.serialNumber

    try await expectErrorFrom { [self] in
      _ = try await ConnectUser.resolve(with: input, in: self.context)
    }.toContain("associated with another Gertrude parent account")

    // old token is not deleted
    let retrievedOldToken = try? await self.db.find(existingUserToken.id)
    expect(retrievedOldToken?.id).not.toBeNil()
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
      serialNumber: "X02VH0Y6JG5J",
      osVersion: "14.2.0",
      isAdmin: false
    )
  }

  var context: Context {
    .init(requestId: "", dashboardUrl: "", ipAddress: nil)
  }
}
