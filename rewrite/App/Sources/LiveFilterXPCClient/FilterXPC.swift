import ClientInterfaces
import Combine
import Core
import Dependencies
import Foundation
import Gertie
import TaggedTime

struct FilterXPC: Sendable {
  @Dependency(\.mainQueue) var scheduler
  @Dependency(\.filterExtension) var filterExtension

  func establishConnection() async throws {
    let checkConnection = await Result { try await checkConnectionHealth() }
    guard checkConnection.isFailure else { return }

    // stored connection can go bad if something happens on the filter side
    // recreating a new connection and sending a message can restore it
    await sharedConnection.replace(with: { newConnection() })

    // the xpc connection channel is created at the moment the app
    // first sends _ANY_ message to the listening filter extension
    // that's why SimpleFirewall has a dummy `register()` proxy endpoint,
    // because you need to send _SOMETHING_ to fire up the connection
    // sending it the test connection healthy message serves the purpose
    try await checkConnectionHealth()
  }

  func checkConnectionHealth() async throws {
    let extensionState = await filterExtension.state()
    guard extensionState != .notInstalled else {
      throw XPCErr.onAppSide(.filterNotInstalled)
    }

    // if this doesn't throw, we know we have a good connection
    // validated by passing random int back and forth
    _ = try await requestAck()
  }

  func requestAck() async throws -> XPC.FilterAck {
    let randomInt = Int.random(in: 0 ... 10000)
    let reply = try await withTimeout(connection: sharedConnection) { filterProxy, continuation in
      filterProxy.receiveAckRequest(
        randomInt: randomInt,
        userId: getuid(),
        reply: continuation.dataHandler
      )
    }

    let ack = try XPC.decode(XPC.FilterAck.self, from: reply)
    if ack.randomInt != randomInt {
      throw XPCErr.onAppSide(.unexpectedIncorrectAck)
    }
    return ack
  }

  func sendUserRules(manifest: AppIdManifest, keys: [FilterKey]) async throws {
    try await establishConnection()

    let manifestData = try XPC.encode(manifest)
    let keysData = try keys.map { try XPC.encode($0) }

    try await withTimeout(connection: sharedConnection) { filterProxy, continuation in
      filterProxy.receiveUserRules(
        userId: getuid(),
        manifestData: manifestData,
        keysData: keysData,
        reply: continuation.dataHandler
      )
    }
  }

  func disconnectUser() async throws {
    try await establishConnection()
    try await withTimeout(connection: sharedConnection) { filterProxy, continuation in
      filterProxy.disconnectUser(getuid(), reply: continuation.dataHandler)
    }
  }

  func endFilterSuspension() async throws {
    try await establishConnection()
    try await withTimeout(connection: sharedConnection) { filterProxy, continuation in
      filterProxy.endSuspension(for: getuid(), reply: continuation.dataHandler)
    }
  }

  func suspendFilter(for duration: Seconds<Int>) async throws {
    try await establishConnection()
    try await withTimeout(connection: sharedConnection) { filterProxy, continuation in
      filterProxy.suspendFilter(
        for: getuid(),
        durationInSeconds: duration.rawValue,
        reply: continuation.dataHandler
      )
    }
  }

  func setBlockStreaming(enabled: Bool) async throws {
    try await establishConnection()
    try await withTimeout(connection: sharedConnection) { filterProxy, continuation in
      filterProxy.setBlockStreaming(
        enabled,
        userId: getuid(),
        reply: continuation.dataHandler
      )
    }
  }

  func setUserExemption(userId: uid_t, enabled: Bool) async throws {
    try await establishConnection()
    try await withTimeout(connection: sharedConnection) { filterProxy, continuation in
      filterProxy.setUserExemption(
        userId,
        enabled: enabled,
        reply: continuation.dataHandler
      )
    }
  }

  func requestExemptUserIds() async throws -> [uid_t] {
    try await establishConnection()
    return try await withTimeout(connection: sharedConnection) { filterProxy, continuation in
      filterProxy.receiveListExemptUserIdsRequest(reply: continuation.dataHandler)
    }
  }

  func sendDeleteAllStoredState() async throws {
    try await establishConnection()
    try await withTimeout(connection: sharedConnection) { filterProxy, continuation in
      filterProxy.deleteAllStoredState(reply: continuation.dataHandler)
    }
  }
}

extension FilterXPC: XPCSender {
  typealias Proxy = AppMessageReceiving
}

func newConnection() -> NSXPCConnection {
  let connection = NSXPCConnection(
    machServiceName: Constants.MACH_SERVICE_NAME,
    options: []
  )
  connection.exportedInterface = NSXPCInterface(with: FilterMessageReceiving.self)
  connection.exportedObject = ReceiveFilterMessage(subject: xpcEventSubject)
  connection.remoteObjectInterface = NSXPCInterface(with: AppMessageReceiving.self)
  connection.resume()
  return connection
}

private let sharedConnection = Connection { newConnection() }
internal let xpcEventSubject = Mutex(PassthroughSubject<XPCEvent.App, Never>())
