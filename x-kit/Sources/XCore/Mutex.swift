import Foundation

/// A back-port of Swift's `Mutex` type for wider platform availability.
/// taken from github.com/pointfreeco/swift-sharing

#if hasFeature(StaticExclusiveOnly)
  @_staticExclusiveOnly
#endif
public struct Mutex<Value: ~Copyable>: ~Copyable {
  private let _lock = NSLock()
  private let _box: Box

  /// Initializes a value of this mutex with the given initial state.
  ///
  /// - Parameter initialValue: The initial value to give to the mutex.
  public init(_ initialValue: consuming sending Value) {
    self._box = Box(initialValue)
  }

  private final class Box {
    var value: Value
    init(_ initialValue: consuming sending Value) {
      self.value = initialValue
    }
  }
}

extension Mutex: @unchecked Sendable where Value: ~Copyable {}

public extension Mutex where Value: ~Copyable {
  /// Calls the given closure after acquiring the lock and then releases ownership.
  borrowing func withLock<Result: ~Copyable, E: Error>(
    _ body: (inout sending Value) throws(E) -> sending Result
  ) throws(E) -> sending Result {
    self._lock.lock()
    defer { _lock.unlock() }
    return try body(&self._box.value)
  }

  /// Attempts to acquire the lock and then calls the given closure if successful.
  borrowing func withLockIfAvailable<Result: ~Copyable, E: Error>(
    _ body: (inout sending Value) throws(E) -> sending Result
  ) throws(E) -> sending Result? {
    guard self._lock.try() else { return nil }
    defer { self._lock.unlock() }
    return try body(&self._box.value)
  }
}

public extension Mutex where Value == Void {
  borrowing func _unsafeLock() {
    self._lock.lock()
  }

  borrowing func _unsafeTryLock() -> Bool {
    self._lock.try()
  }

  borrowing func _unsafeUnlock() {
    self._lock.unlock()
  }
}
