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
    await connection.recreate()
    try await isConnectionHealthy()
  }

  func isConnectionHealthy() async throws {
    let extensionState = await filterExtension.state()
    guard extensionState != .notInstalled else {
      throw Err.filterNotInstalled
    }

    let randomInt = Int.random(in: 0 ... 10000)
    let intData = try encode(randomInt)
    let reply = try await withTimeout { filterProxy, continuation in
      filterProxy.ackRandomInt(intData, reply: continuation.resumingHandler)
    }

    if try decode(Int.self, from: reply) != randomInt {
      throw Err.unexpectedIncorrectAck
    }
  }

  // if we try to reach the filter extension, and it's not installed or for some
  // reason never gets back to us, the task will hang forever. this is the only
  // way i could figure out to watch the passing of time and cancel the task
  // if it dissapears into the void ¯\_(ツ)_/¯
  func withTimeout<T: Sendable>(
    function: String = #function,
    _ body: @escaping @Sendable (AppMessageReceiving, CheckedContinuation<T, Error>) -> Void
  ) async throws -> T {
    let isolatedData = ActorIsolated<T?>(nil)
    let task = Task {
      let data = try await connection.get.unlock().withContinuation(function: function, body)
      await isolatedData.setValue(data)
    }

    var ticks = 0
    var stride = 1
    while true {
      let data = await isolatedData.value
      if let data {
        return data
      }
      try await scheduler.sleep(for: .microseconds(stride))
      ticks += stride
      if ticks == 100 {
        stride = 100
      } else if ticks == 50000 {
        // increase to waiting 5 milliseconds per/check
        stride = 5000
      } else if ticks >= 3_000_000 {
        // quit after 3 seconds
        task.cancel()
        throw Err.timeout
      }
    }
  }
}

func encode<T: Encodable>(_ value: T, fn: StaticString = #function) throws -> Data {
  do {
    return try JSONEncoder().encode(value)
  } catch {
    throw FilterXPCClient.Error.encode(fn: fn, type: T.self, error: error)
  }
}

func decode<T: Decodable>(
  _ type: T.Type,
  from data: Data,
  fn: StaticString = #function
) throws -> T {
  do {
    return try JSONDecoder().decode(T.self, from: data)
  } catch {
    throw FilterXPCClient.Error.decode(fn: fn, type: T.self, error: error)
  }
}

func createConnection() -> NSXPCConnection {
  let conn = NSXPCConnection(machServiceName: Constants.MACH_SERVICE_NAME, options: [])
  conn.exportedInterface = NSXPCInterface(with: FilterMessageReceiving.self)
  conn.exportedObject = ReceiveFilterMessage()
  conn.remoteObjectInterface = NSXPCInterface(with: AppMessageReceiving.self)
  conn.resume()
  return conn
}

// wha????
@objc class ReceiveFilterMessage: NSObject, FilterMessageReceiving {
  func ackRandomInt(_ intData: Data, reply: @escaping (Data?, Error?) -> Void) {
    fatalError("do it")
  }
}

typealias Err = FilterXPCClient.Error

private let connection = Connection()

actor Connection {
  private var connection: ThreadSafe<NSXPCConnection>

  var get: ThreadSafe<NSXPCConnection> {
    connection
  }

  init() {
    connection = ThreadSafe(createConnection())
  }

  func recreate() {
    connection = ThreadSafe(createConnection())
  }
}
