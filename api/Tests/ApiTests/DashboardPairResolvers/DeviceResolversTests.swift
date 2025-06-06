import Dependencies
import XCTest
import XExpect

@testable import Api

final class DeviceResolversTests: ApiTestCase, @unchecked Sendable {
  func testGetDevices() async throws {
    try await self.db.delete(all: Computer.self)
    let child = try await self.child().withDevice { $0.appVersion = "2.2.2" }
    var device = child.computer
    device.appReleaseChannel = .canary
    device.customName = "Pinky"
    device.serialNumber = "1234567890"
    device.modelIdentifier = "MacBookPro16,1"
    try await self.db.update(device)

    let child2 = try await self.db.create(Child(parentId: child.parentId, name: "Bob"))

    // proves that we take the highest app version
    try await self.db.create(ComputerUser(
      childId: child2.id,
      computerId: device.id,
      isAdmin: false,
      appVersion: "2.0.1", // <-- lower app version
      username: "Bob",
      fullUsername: "Bob",
      numericId: 504
    ))

    try await withDependencies {
      $0.websockets.status = { _ in .filterOn }
    } operation: {
      var singleOutput = try await GetDevice.resolve(
        with: device.id.rawValue,
        in: context(child.parent)
      )

      var expectedDeviceOutput = GetDevice.Output(
        id: device.id,
        name: "Pinky",
        releaseChannel: .canary,
        users: [
          .init(id: child.id, name: child.name, status: .filterOn),
          .init(id: child2.id, name: child2.name, status: .filterOn),
        ],
        appVersion: "2.2.2",
        serialNumber: "1234567890",
        modelIdentifier: "MacBookPro16,1",
        modelFamily: .macBookPro,
        modelTitle: "16\" MacBook Pro (2019)"
      )

      sortUsers(in: &singleOutput, atPath: \.users)
      sortUsers(in: &expectedDeviceOutput, atPath: \.users)
      expect(singleOutput).toEqual(expectedDeviceOutput)

      var allDevicesOutput = try await GetDevices.resolve(in: context(child.parent))
      sortUsers(in: &allDevicesOutput, atPath: \.[0].users)
      expect(allDevicesOutput).toEqual([expectedDeviceOutput])
    }
  }

  func testSaveDevice() async throws {
    let child = try await self.childWithComputer()
    var device = child.computer
    device.appReleaseChannel = .stable
    device.customName = nil
    try await self.db.update(device)

    var output = try await SaveDevice.resolve(
      with: .init(id: device.id, name: "Pinky", releaseChannel: .beta),
      in: context(child.parent)
    )

    expect(output).toEqual(.success)

    let retrieved = try await self.db.find(device.id)
    expect(retrieved.customName).toEqual("Pinky")
    expect(retrieved.appReleaseChannel).toEqual(.beta)

    output = try await SaveDevice.resolve(
      with: .init(
        id: device.id,
        name: nil, // <-- remove name
        releaseChannel: .beta
      ),
      in: context(child.parent)
    )

    let retrievedAgain = try await self.db.find(device.id)
    expect(retrievedAgain.customName).toBeNil()
  }
}

// helpers

func sortUsers<Root>(
  in root: inout Root,
  atPath keyPath: WritableKeyPath<Root, [GetDevice.Output.User]>
) {
  root[keyPath: keyPath].sort(by: { $0.name < $1.name })
}
