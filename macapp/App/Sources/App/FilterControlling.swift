import ClientInterfaces
import ComposableArchitecture
import Foundation
import os.log

protocol FilterControlling: RootReducing {
  var filter: FilterExtensionClient { get }
  var mainQueue: AnySchedulerOf<DispatchQueue> { get }
  var xpc: FilterXPCClient { get }
  var api: ApiClient { get }
  func afterFilterChange(_ send: Send<Action>, repairing: Bool) async
}

extension FilterControlling {
  func installFilter(_ send: Send<Action>) async throws {
    await api.securityEvent(.systemExtensionChangeRequested, "install")
    _ = await filter.install()
    try await mainQueue.sleep(for: .milliseconds(10))
    let result = await xpc.establishConnection()
    os_log("[G•] APP FilterControlling.installFilter() result: %{public}s", "\(result)")
    await afterFilterChange(send, repairing: false)
  }

  func restartFilter(_ send: Send<Action>) async throws {
    await api.securityEvent(.systemExtensionChangeRequested, "restart")
    _ = await filter.restart()
    try await mainQueue.sleep(for: .milliseconds(100))
    let result = await xpc.establishConnection()
    os_log("[G•] APP FilterControlling.restartFilter() result: %{public}s", "\(result)")
    await afterFilterChange(send, repairing: false)
  }

  func startFilter(_ send: Send<Action>) async throws {
    await api.securityEvent(.systemExtensionChangeRequested, "start")
    _ = await filter.start()
    try await mainQueue.sleep(for: .milliseconds(100))
    let result = await xpc.establishConnection()
    os_log("[G•] APP FilterControlling.startFilter() result: %{public}s", "\(result)")
    await afterFilterChange(send, repairing: false)
  }

  func replaceFilter(
    _ send: Send<Action>,
    attempt: Int = 1,
    reinstallOnFail: Bool = true
  ) async throws {
    _ = await filter.replace()
    await api.securityEvent(.systemExtensionChangeRequested, "replace")
    var result = await xpc.establishConnection()
    os_log(
      "[G•] APP FilterControlling.replaceFilter() attempt: %{public}d, result: %{public}s",
      attempt,
      "\(result)"
    )
    await afterFilterChange(send, repairing: true)

    // trying up to 4 times seems to get past some funky states fairly
    // reliably, especially the one i observe locally only, where the filter
    // shows up in an "orange" state in the system preferences pane
    if attempt < 4, await xpc.notConnected() {
      return try await self.replaceFilter(
        send,
        attempt: attempt + 1,
        reinstallOnFail: reinstallOnFail
      )
    }

    if reinstallOnFail, await xpc.notConnected() {
      os_log("[G•] APP FilterControlling.replaceFilter() failed, reinstalling")
      _ = await filter.reinstall()
      try await mainQueue.sleep(for: .milliseconds(500))
      result = await xpc.establishConnection()
      os_log("[G•] APP FilterControlling.replaceFilter() final: %{public}s", "\(result)")
      await afterFilterChange(send, repairing: false)
    }
  }
}
