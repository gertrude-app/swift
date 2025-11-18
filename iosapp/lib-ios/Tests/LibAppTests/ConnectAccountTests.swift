import ComposableArchitecture
import IOSRoute
import Testing

@testable import LibApp
@testable import LibClients

@MainActor
@Test func codeSubmittedSuccess() async throws {
  let connectDeviceInvocations = LockIsolated(0)

  let store = TestStore(initialState: ConnectAccount.State()) {
    ConnectAccount()
  } withDependencies: {
    $0.device.vendorId = { UUID(0) }
    $0.api.connectDevice = { @Sendable code, vid in
      #expect(code == 123_456)
      #expect(vid == UUID(0))
      connectDeviceInvocations.withValue { $0 += 1 }
      return ChildIOSDeviceData_b1(
        childId: UUID(1),
        token: UUID(2),
        deviceId: UUID(3),
        childName: "Franny",
      )
    }
  }

  await store.send(.codeSubmitted(123_456)) {
    $0.screen = .connecting
  }

  await store.receive(.connectionSucceeded(childData: .init(
    childId: UUID(1),
    token: UUID(2),
    deviceId: UUID(3),
    childName: "Franny",
  ))) {
    $0.screen = .connected(childName: "Franny")
  }

  #expect(connectDeviceInvocations.value == 1)
}

@MainActor
@Test func codeSubmittedFailsWhenNoVendorId() async throws {
  let store = TestStore(initialState: ConnectAccount.State()) {
    ConnectAccount()
  } withDependencies: {
    $0.device.vendorId = { nil }
    $0.api.connectDevice = { @Sendable _, _ in
      fatalError("connectDevice should not be called")
    }
  }

  await store.send(.codeSubmitted(123_456)) {
    $0.screen = .connecting
  }

  await store.receive(.setScreen(.connectionFailed(error: "No vendor ID found"))) {
    $0.screen = .connectionFailed(error: "No vendor ID found")
  }
}

@MainActor
@Test func codeSubmittedFailsWhenApiErrors() async throws {
  let store = TestStore(initialState: ConnectAccount.State()) {
    ConnectAccount()
  } withDependencies: {
    $0.device.vendorId = { UUID(3) }
    $0.api.connectDevice = { @Sendable _, _ in
      struct TestError: Error, LocalizedError {
        var errorDescription: String? { "Invalid code" }
      }
      throw TestError()
    }
  }

  await store.send(.codeSubmitted(999_999)) {
    $0.screen = .connecting
  }

  await store.receive(.setScreen(.connectionFailed(error: "Invalid code"))) {
    $0.screen = .connectionFailed(error: "Invalid code")
  }
}

@MainActor
@Test func receivedConnectionErrorSetsScreen() async throws {
  let store = TestStore(initialState: ConnectAccount.State(screen: .connecting)) {
    ConnectAccount()
  }

  await store.send(.receivedConnectionError("Network error")) {
    $0.screen = .connectionFailed(error: "Network error")
  }
}
