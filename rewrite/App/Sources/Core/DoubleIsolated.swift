import Foundation

public actor DoubleIsolated<T> {
  private var isolated: ThreadSafe<T>

  public var get: ThreadSafe<T> {
    isolated
  }

  public init(_ isolated: ThreadSafe<T>) {
    self.isolated = isolated
  }

  public func replace(with newValue: ThreadSafe<T>) {
    isolated = newValue
  }
}
