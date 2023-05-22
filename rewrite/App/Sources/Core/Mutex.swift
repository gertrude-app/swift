import Foundation

public class Mutex<T>: @unchecked Sendable {
  private var _value: T
  private let lock = NSLock()

  public init(_ value: T) {
    _value = value
  }

  public func withValue<R: Sendable>(_ closure: (T) throws -> R) rethrows -> R {
    lock.lock()
    defer { lock.unlock() }
    return try closure(_value)
  }

  public func replace(_ closure: @Sendable () -> T) {
    lock.lock()
    defer { lock.unlock() }
    _value = closure()
  }

  public func replace(with value: T) {
    lock.lock()
    defer { lock.unlock() }
    _value = value
  }
}

public extension Mutex where T: Sendable {
  func transition(_ closure: @Sendable (T) -> T) {
    lock.lock()
    defer { lock.unlock() }
    let previous = _value
    _value = closure(previous)
  }
}
