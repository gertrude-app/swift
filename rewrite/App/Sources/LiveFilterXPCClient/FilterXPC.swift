import Combine
import Core
import Dependencies
import Foundation
import Models

struct FilterXPC: Sendable {
  @Dependency(\.mainQueue) var scheduler
  @Dependency(\.filterExtension) var filterExtension

  func establishConnection() async throws {
    let checkConnection = await Result { try await isConnectionHealthy() }
    guard checkConnection.isFailure else { return }

    // stored connection can go bad if something happens on the filter side
    // recreating a new connection and sending a message can restore it
    await sharedConnection.replace(with: { newConnection() })

    // the xpc connection channel is created at the moment the app
    // first sends _ANY_ message to the listening filter extension
    // that's why SimpleFirewall has a dummy `register()` proxy endpoint,
    // because you need to send _SOMETHING_ to fire up the connection
    // sending it the test connection healthy message serves the purpose
    try await isConnectionHealthy()
  }

  func isConnectionHealthy() async throws {
    let extensionState = await filterExtension.state()
    guard extensionState != .notInstalled else {
      throw XPCErr.onAppSide(.filterNotInstalled)
    }

    let randomInt = Int.random(in: 0 ... 10000)
    let intData = try XPC.encode(randomInt)

    let reply = try await withTimeout(connection: sharedConnection) { filterProxy, continuation in
      filterProxy.ackRandomInt(intData, reply: continuation.resumingHandler)
    }

    if try XPC.decode(Int.self, from: reply) != randomInt {
      throw XPCErr.onAppSide(.unexpectedIncorrectAck)
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
internal let xpcEventSubject = Mutex(PassthroughSubject<XPCEvent, Never>())
