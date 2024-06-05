import XCTest
import XExpect

@testable import Api

final class DeviceResolversTests: ApiTestCase {
  func testGetDevices() async throws {
    try await Device.deleteAll()
    let user = try await Entities.user().withDevice { $0.appVersion = "2.2.2" }
    let device = user.adminDevice
    device.appReleaseChannel = .canary
    device.customName = "Pinky"
    device.serialNumber = "1234567890"
    device.modelIdentifier = "MacBookPro16,1"
    try await device.save()

    let user2 = try await User.create(.init(adminId: user.adminId, name: "Bob"))

    // proves that we take the highest app version
    try await UserDevice.create(.init(
      userId: user2.id,
      deviceId: device.id,
      isAdmin: false,
      appVersion: "2.0.1", // <-- lower app version
      username: "Bob",
      fullUsername: "Bob",
      numericId: 504
    ))

    let singleOutput = try await GetDevice.resolve(
      with: device.id.rawValue,
      in: context(user.admin)
    )

    let expectedDeviceOutput = GetDevice.Output(
      id: device.id,
      name: "Pinky",
      releaseChannel: .canary,
      users: [
        .init(id: user.id, name: user.name, isOnline: false),
        .init(id: user2.id, name: user2.name, isOnline: false),
      ],
      appVersion: "2.2.2",
      serialNumber: "1234567890",
      modelIdentifier: "MacBookPro16,1",
      modelFamily: .macBookPro,
      modelTitle: "16\" MacBook Pro (2019)"
    )

    expect(singleOutput).toEqual(expectedDeviceOutput)

    let allDevicesOutput = try await GetDevices.resolve(in: context(user.admin))
    expect(allDevicesOutput).toEqual([expectedDeviceOutput])
  }

  func testSaveDevice() async throws {
    let user = try await Entities.user().withDevice()
    let device = user.adminDevice
    device.appReleaseChannel = .stable
    device.customName = nil
    try await device.save()

    var output = try await SaveDevice.resolve(
      with: .init(id: device.id, name: "Pinky", releaseChannel: .beta),
      in: context(user.admin)
    )

    expect(output).toEqual(.success)

    let retrieved = try await Device.find(device.id)
    expect(retrieved.customName).toEqual("Pinky")
    expect(retrieved.appReleaseChannel).toEqual(.beta)

    output = try await SaveDevice.resolve(
      with: .init(
        id: device.id,
        name: nil, // <-- remove name
        releaseChannel: .beta
      ),
      in: context(user.admin)
    )

    let retrievedAgain = try await Device.find(device.id)
    expect(retrievedAgain.customName).toBeNil()
  }
}
