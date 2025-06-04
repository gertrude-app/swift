import Dependencies
import DuetSQL
import Gertie
import MacAppRoute
import XCore
import XCTest
import XExpect

@testable import Api

final class ConnectUserResolversTests: ApiTestCase, @unchecked Sendable {
  override func invokeTest() {
    withDependencies {
      $0.verificationCode = .liveValue
    } operation: {
      super.invokeTest()
    }
  }

  func testConnectUser_createNewDevice() async throws {
    let child = try await self.child()
    let code = await with(dependency: \.ephemeral)
      .createPendingAppConnection(child.id)

    let input = input(code)
    let childData = try await ConnectUser.resolve(with: input, in: self.context)

    expect(childData.id).toEqual(child.id.rawValue)
    expect(childData.name).toEqual(child.name)

    let computerUser = try await self.db.find(ComputerUser.Id(childData.deviceId))
    let device = try await self.db.find(computerUser.computerId)

    expect(computerUser.username).toEqual(input.username)
    expect(computerUser.fullUsername).toEqual(input.fullUsername)
    expect(computerUser.numericId).toEqual(input.numericId)
    expect(computerUser.appVersion).toEqual(input.appVersion)
    expect(computerUser.isAdmin).toEqual(input.isAdmin)
    expect(device.serialNumber).toEqual(input.serialNumber)
    expect(device.modelIdentifier).toEqual(input.modelIdentifier)
    expect(device.osVersion).toEqual(Semver("14.2.0"))

    let token = try await MacAppToken.query()
      .where(.value == childData.token)
      .first(in: self.db)

    expect(token.childId).toEqual(child.id)
  }

  func testConnectUser_twoUsersSameComputer() async throws {
    try await self.db.delete(all: Device.self)
    let child1 = try await self.child()
    let code1 = await with(dependency: \.ephemeral)
      .createPendingAppConnection(child1.id)

    let child2 = try await self.child { $0.parentId = child1.parent.id }
    let code2 = await with(dependency: \.ephemeral)
      .createPendingAppConnection(child2.id)

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
      let existingUser = try await self.childWithComputer()
      let existingMacAppToken = try await self.db.create(MacAppToken(
        childId: existingUser.id,
        computerUserId: existingUser.computerUser.id
      ))

      // different user, owned by same admin
      let newUser = try await self.child(with: \.parentId, of: existingUser.parent.id)
      let code = await with(dependency: \.ephemeral)
        .createPendingAppConnection(newUser.model.id)

      // happy path, the device exists, registered to another user, but that's OK
      // because the same admin owns both users, so switch it over
      newUser.model.parentId = existingUser.parent.model.id
      try await self.db.update(newUser.model)

      var input = input(code)
      input.numericId = existingUser.computerUser.numericId
      input.serialNumber = existingUser.computer.serialNumber
      let childData = try await ConnectUser.resolve(with: input, in: self.context)

      expect(childData.id).toEqual(newUser.id.rawValue)
      expect(childData.name).toEqual(newUser.name)

      let retrievedDevice = try await self.db.find(existingUser.computerUser.id)
      expect(retrievedDevice.childId).toEqual(newUser.model.id)

      let retrievedOldToken = try await self.db.find(existingMacAppToken.id)
      expect(retrievedOldToken.deletedAt).not.toBeNil()
    }
  }

  // test sanity check, computer/user registered to a different admin
  func testConnectUser_ExistingDeviceToDifferentUser_FailsIfDifferentAdmin() async throws {
    let existingUser = try await self.childWithComputer()
    let existingMacAppToken = try await self.db.create(MacAppToken(
      childId: existingUser.model.id,
      computerUserId: existingUser.computerUser.id
    ))

    // this user is from a DIFFERENT admin, so it should fail
    let newUser = try await self.child()
    let code = await with(dependency: \.ephemeral)
      .createPendingAppConnection(newUser.model.id)

    var input = input(code)
    input.numericId = existingUser.computerUser.numericId
    input.serialNumber = existingUser.computer.serialNumber

    try await expectErrorFrom { [self] in
      _ = try await ConnectUser.resolve(with: input, in: self.context)
    }.toContain("associated with another Gertrude parent account")

    // old token is not deleted
    let retrievedOldToken = try? await self.db.find(existingMacAppToken.id)
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
