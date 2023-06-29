import ClientInterfaces
import ComposableArchitecture
import Foundation

protocol FilterControlling: RootReducing {
  var filter: FilterExtensionClient { get }
  var mainQueue: AnySchedulerOf<DispatchQueue> { get }
  var xpc: FilterXPCClient { get }
  func afterFilterChange(_ send: Send<Action>) async
}

extension FilterControlling {
  func afterFilterChange(_ send: Send<Action>) async {}

  func installFilter(_ send: Send<Action>) async throws {
    _ = await filter.install()
    try await mainQueue.sleep(for: .milliseconds(10))
    _ = await xpc.establishConnection()
    await afterFilterChange(send)
  }

  func restartFilter(_ send: Send<Action>) async throws {
    _ = await filter.restart()
    try await mainQueue.sleep(for: .milliseconds(100))
    _ = await xpc.establishConnection()
    await afterFilterChange(send)
  }

  func replaceFilter(_ send: Send<Action>, retryOnce retry: Bool = false) async throws {
    _ = await filter.replace()
    try await mainQueue.sleep(for: .milliseconds(500))
    _ = await xpc.establishConnection()
    await afterFilterChange(send)
    if retry, await xpc.notConnected() {
      try await replaceFilter(send, retryOnce: false)
    }
  }

  func replaceFilterIfNotConnected(_ send: Send<Action>, retryOnce: Bool = false) async throws {
    if await xpc.notConnected() {
      try await replaceFilter(send, retryOnce: retryOnce)
    }
  }
}
