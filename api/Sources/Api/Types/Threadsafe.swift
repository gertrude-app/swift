import Foundation

// https://github.com/raywenderlich/vpr-materials/blob/editions/3.0/30-websockets/projects/final/share-touch-server/Sources/App/Generic/ThreadSafe.swift
@propertyWrapper struct ThreadSafe<Value> {
  private var value: Value
  private let lock = Lock()

  init(wrappedValue value: Value) {
    self.value = value
  }

  var wrappedValue: Value {
    get { lock.run { value } }
    set { lock.run { value = newValue } }
  }
}

private struct Lock {
  private let nslock = NSLock()

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

  private func lock() {
    nslock.lock()
  }

  private func unlock() {
    nslock.unlock()
  }
}
