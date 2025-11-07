import Dependencies
import Foundation

public protocol XPCSender {
  associatedtype Proxy: Any
  var scheduler: AnySchedulerOf<DispatchQueue> { get }
}

public extension XPCSender {
  // if we try to reach the other side, the task can hang forever
  // without any reply or error, as in when the app tries to send a message
  // to the filter extension when it is not installed. this is the only
  // way i could figure out to watch the passing of time and cancel the task
  // if it dissapears into the void ¯\_(ツ)_/¯
  func withTimeout<T: Sendable>(
    function: String = #function,
    of seconds: Double = 3,
    connection: Connection,
    operation: @escaping @Sendable (Proxy, CheckedContinuation<T, Error>) -> Void,
  ) async throws -> T {
    let isolatedData = ActorIsolated<T?>(nil)
    let isolatedError = ActorIsolated<Error?>(nil)

    let task = Task {
      do {
        try await connection.withUnderlying { nsxpc in
          let data = try await nsxpc.withContinuation(function: function, operation)
          await isolatedData.setValue(data)
        }
      } catch {
        await isolatedError.setValue(error)
      }
    }

    var ticks = 0
    var stride = 1
    let maxMicroseconds = Int(seconds * 1_000_000)

    while true {
      let data = await isolatedData.value
      if let data {
        return data
      }

      let error = await isolatedError.value
      if let error {
        throw XPCErr(error)
      }

      try await scheduler.sleep(for: .microseconds(stride))
      ticks += stride

      // most xpc ops seem to finish in < 20 microseconds
      // so poll fast during that time, but if we get past
      // that, it's likely we'll timeout, so wait longer
      // as we approach deadline, to save iterations/computation
      if ticks == 100 {
        stride = 100
      } else if ticks == 50000 {
        stride = 5000 // 5 milliseconds
      } else if ticks >= maxMicroseconds {
        task.cancel()
        throw XPCErr.timeout
      }
    }
  }
}
