import Foundation

public class Mutex<T>: @unchecked Sendable {
  private var _value: T
  private let lock = NSLock()

  public init(_ value: T) {
    self._value = value
  }

  public func withValue<R: Sendable>(_ closure: (T) throws -> R) rethrows -> R {
    self.lock.lock()
    defer { lock.unlock() }
    return try closure(self._value)
  }

  public func replace(_ closure: @Sendable () -> T) {
    self.lock.lock()
    defer { lock.unlock() }
    self._value = closure()
  }

  @discardableResult
  public func replace(with value: T) -> T {
    self.lock.lock()
    defer { lock.unlock() }
    let previous = self._value
    self._value = value
    return previous
  }
}

public extension Mutex where T: Sendable {
  var value: T {
    self.withValue { $0 }
  }

  func transition(_ closure: @Sendable (T) -> T) {
    self.lock.lock()
    defer { lock.unlock() }
    let previous = self._value
    self._value = closure(previous)
  }
}
