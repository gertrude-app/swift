import Foundation

struct ThreadSafe<Value>: @unchecked Sendable {
  private var _value: Value
  private let lock = Lock()

  init(wrapped value: Value) {
    _value = value
  }

  var value: Value {
    get { lock.run { _value } }
    set { lock.run { _value = newValue } }
  }
}

private struct Lock {
  private let nslock = NSLock()
  init() {}

  func lock() {
    nslock.lock()
  }

  func unlock() {
    nslock.unlock()
  }

  func run(_ closure: () throws -> Void) rethrows {
    lock()
    try closure()
    unlock()
  }

  func run<T>(_ closure: () throws -> T) rethrows -> T {
    lock()
    defer { unlock() }
    return try closure()
  }
}
