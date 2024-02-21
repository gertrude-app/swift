import Combine
import ComposableArchitecture
import Core
import Foundation
import Gertie

import os.log

public struct FilterStore: NetworkFilter {
  let store: StoreOf<Filter>
  let viewStore: ViewStoreOf<Filter>

  public var state: Filter.State { viewStore.state }

  // public let udsServer: ServerUDS!

  @Dependency(\.security) public var security

  public init() {
    store = Store(initialState: Filter.State(), reducer: { Filter() })
    viewStore = ViewStore(store, observe: { $0 })
    viewStore.send(.extensionStarted)

    Task {

      let udsServer = ServerUDS()
      udsServer.startBroadcasting()

      // Task {
      //   try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconds
      let str = "hello from sys-ext"
      let data: Data = str.data(using: .utf8)!

      try? await Task.sleep(nanoseconds: 500_000_000)
      udsServer.sendData(data)
      udsServer.readData()
      try? await Task.sleep(nanoseconds: 500_000_000)
      udsServer.sendData(data)
      udsServer.readData()
      try? await Task.sleep(nanoseconds: 500_000_000)
      udsServer.sendData(data)
      udsServer.readData()
      try? await Task.sleep(nanoseconds: 500_000_000)
      udsServer.sendData(data)
      udsServer.readData()
      try? await Task.sleep(nanoseconds: 500_000_000)
      udsServer.sendData(data)
      udsServer.readData()
      try? await Task.sleep(nanoseconds: 500_000_000)
      udsServer.sendData(data)
      udsServer.readData()
      try? await Task.sleep(nanoseconds: 500_000_000)
      udsServer.sendData(data)
      udsServer.readData()
      try? await Task.sleep(nanoseconds: 500_000_000)
      udsServer.sendData(data)
      udsServer.readData()
      try? await Task.sleep(nanoseconds: 500_000_000)
      udsServer.sendData(data)
      udsServer.readData()
      try? await Task.sleep(nanoseconds: 500_000_000)
      udsServer.sendData(data)
      udsServer.readData()
    }
    // }

    // DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
    //   udsServer.sendData(data)
    // }

    // DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
    //   self.readData()
    // }
    // let socket = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
    // os_log("[G•] filter create socket %{publid}d", socket)

    // if let myUrl = FileManager.default
    //   .containerURL(
    //     forSecurityApplicationGroupIdentifier: "WFN83LM943.com.netrivet.gertrude.group"
    //   ) {
    //   os_log("[G•] socket container url %{public}s", myUrl.absoluteString)
    // } else {
    //   os_log("[G•] filter socket url FAILED")
    // }

    // let socketPath =
    //   URL(
    //     fileURLWithPath: "file:///Users/jared/Library/Group Containers/WFN83LM943.com.netrivet.gertrude.group"
    //   )
    //   .appendingPathComponent("GertrudeUDS").path

    // var address = sockaddr_un()
    // address.sun_family = sa_family_t(AF_UNIX)
    // socketPath.withCString { ptr in
    //   withUnsafeMutablePointer(to: &address.sun_path.0) { dest in
    //     _ = strcpy(dest, ptr)
    //   }
    // }

    // os_log("[G•] Binding to socket path: %{public}s", socketPath)
    // unlink(socketPath) // unlink first
    // if Darwin.bind(
    //   socket,
    //   withUnsafePointer(to: &address) {
    //     $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { $0 }
    //   },
    //   socklen_t(MemoryLayout<sockaddr_un>.size)
    // ) == -1 {
    //   os_log("[G•] Error binding socket - %{public}s", String(cString: strerror(errno)))
    // } else {
    //   os_log("[G•] Bound socket")
    // }
  }

  public func sendBlocked(_ flow: FilterFlow, auditToken: Data?) {
    let app = appDescriptor(for: flow.bundleId ?? "(no bundle id)", auditToken: auditToken)
    viewStore.send(.flowBlocked(flow, app))
  }

  public func shouldSendBlockDecisions() -> AnyPublisher<Bool, Never> {
    viewStore.publisher.blockListeners.map { !$0.isEmpty }.eraseToAnyPublisher()
  }

  public func appCache(insert descriptor: AppDescriptor, for bundleId: String) {
    viewStore.send(.cacheAppDescriptor(bundleId, descriptor))
  }

  public func appCache(get bundleId: String) -> AppDescriptor? {
    state.appCache[bundleId]
  }

  public func sendExtensionStopping() {
    viewStore.send(.extensionStopping)
  }
}
