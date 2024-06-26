import Foundation

/// One-time transfer of ownership across actor boundaries for non-Sendable types.
/// adapted from `OwnershipTransferring` in https://github.com/ChimeHQ/ConcurrencyPlus
public final class Move<NonSendable>: @unchecked Sendable {
  private var value: NonSendable?
  private let lock = NSLock()

  public init(_ value: NonSendable) {
    self.value = value
  }

  deinit {
    if value != nil {
      preconditionFailure("deallocating an Move before a transfer has occurred")
    }
  }

  public var hasBeenTaken: Bool {
    self.lock.lock()
    defer { lock.unlock() }
    return self.value == nil
  }

  public func take(replacing newValue: NonSendable) -> NonSendable {
    self.lock.lock()
    defer { lock.unlock() }
    guard let give = value else {
      preconditionFailure("Ownership has already been transferred")
    }
    self.value = newValue
    return give
  }

  /// Safely assume ownership of the wrapped value.
  public func consume() -> NonSendable {
    self.lock.lock()
    defer { lock.unlock() }
    guard let give = value else {
      preconditionFailure("Ownership has already been transferred")
    }
    self.value = nil
    return give
  }
}
