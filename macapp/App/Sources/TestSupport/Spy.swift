import ComposableArchitecture
import Foundation

public struct Mock<T> {
  var invocations: ActorIsolated<Int>
  public var fn: @Sendable () async -> T
  public var called: Bool { get async { await self.invocations.value > 0 } }
  public var calls: [()] {
    get async {
      await Array(repeating: (), count: self.invocations.value)
    }
  }
}

public struct MockSync<T> {
  var invocations: LockIsolated<Int>
  public var fn: @Sendable () -> T
  public var called: Bool { self.invocations.value > 0 }
}

public struct Spy<T, Arg> {
  var invocations: ActorIsolated<[Arg]>
  public var fn: @Sendable (Arg) async -> T
  public var called: Bool { get async { await self.calls.isEmpty == false } }
  public var calls: [Arg] { get async { await self.invocations.value } }
}

public struct SpySync<T, Arg> {
  var invocations: LockIsolated<[Arg]>
  public var fn: @Sendable (Arg) -> T
  public var called: Bool { !self.calls.isEmpty }
  public var calls: [Arg] { self.invocations.value }
}

public struct Spy2<T, Arg1, Arg2> {
  var invocations: ActorIsolated<[Both<Arg1, Arg2>]>
  public var fn: @Sendable (Arg1, Arg2) async -> T
  public var called: Bool { get async { await self.calls.isEmpty == false } }
  public var calls: [Both<Arg1, Arg2>] { get async { await self.invocations.value } }
}

public struct Spy3<T, Arg1, Arg2, Arg3> {
  var invocations: ActorIsolated<[Three<Arg1, Arg2, Arg3>]>
  public var fn: @Sendable (Arg1, Arg2, Arg3) async -> T
  public var numInvocations: Int {
    get async { await self.invocations.value.count }
  }
}

public struct ThrowingSpy<T, Arg> {
  var invocations: ActorIsolated<[Arg]>
  public var fn: @Sendable (Arg) async throws -> T
  public var calls: [Arg] { get async { await self.invocations.value } }
  public var called: Bool { get async { await self.calls.isEmpty == false } }
}

public func mock<T>(once value: T) -> Mock<T> {
  mock(returning: [value])
}

public func mock<T>(always value: T) -> Mock<T> {
  mock(returning: [], then: value)
}

public func mockFn<T>(once value: T) -> @Sendable () async -> T {
  mock(returning: [value]).fn
}

public func mockFn<T>(always value: T) -> @Sendable () async -> T {
  mock(returning: [], then: value).fn
}

public func mockFn<T>(
  returning values: [T],
  then fallback: T? = nil
) -> @Sendable () async -> T {
  mock(returning: values, then: fallback).fn
}

public func mock<T>(returning values: [T], then fallback: T? = nil) -> Mock<T> {
  let returns = ActorIsolated<[T]>(values)
  let invocations = ActorIsolated(0)
  return .init(
    invocations: invocations,
    fn: {
      let currentInvocations = await invocations.value
      await invocations.setValue(currentInvocations + 1)
      var current = await returns.value
      let returnValue: T
      if current.count > 0 {
        returnValue = current.removeFirst()
        let updated = current
        await returns.setValue(updated)
      } else if let fallback {
        returnValue = fallback
      } else {
        fatalError(
          "mock<\(String(reflecting: T.self))> called more than expected number of times \(values.count)"
        )
      }
      return returnValue
    }
  )
}

public func mockSync<T>(returning values: [T], then fallback: T? = nil) -> MockSync<T> {
  let returns = LockIsolated<[T]>(values)
  let invocations = LockIsolated(0)
  return .init(
    invocations: invocations,
    fn: {
      let currentInvocations = invocations.value
      invocations.setValue(currentInvocations + 1)
      var current = returns.value
      let returnValue: T
      if current.count > 0 {
        returnValue = current.removeFirst()
        let updated = current
        returns.setValue(updated)
      } else if let fallback {
        returnValue = fallback
      } else {
        fatalError(
          "mock<\(String(reflecting: T.self))> called more than expected number of times \(values.count)"
        )
      }
      return returnValue
    }
  )
}

public func succeed<T, Arg>(with value: T, capturing: Arg.Type) -> ThrowingSpy<T, Arg> {
  spy(returning: [], then: value)
}

public func spy<T, Arg>(returning values: [T], then fallback: T? = nil) -> ThrowingSpy<T, Arg> {
  let returns = ActorIsolated<[T]>(values)
  let invocations = ActorIsolated<[Arg]>([])
  let invoked = ActorIsolated(false)
  return .init(
    invocations: invocations,
    fn: { arg in
      let currentInvocations = await invocations.value
      await invocations.setValue(currentInvocations + [arg])
      await invoked.setValue(true)
      var current = await returns.value
      let returnValue: T
      if current.count > 0 {
        returnValue = current.removeFirst()
        let updated = current
        await returns.setValue(updated)
      } else if let fallback {
        returnValue = fallback
      } else {
        fatalError(
          "spy<\(String(reflecting: T.self)), \(String(reflecting: Arg.self))> called more than expected number of times \(values.count)"
        )
      }

      return returnValue
    }
  )
}

public func spy<T, Arg>(on arg: Arg.Type, returning value: T) -> Spy<T, Arg> {
  spy(returning: [], then: value)
}

public func spySync<T, Arg>(on arg: Arg.Type, returning value: T) -> SpySync<T, Arg> {
  spySync(returning: [], then: value)
}

public func spySync<T, Arg>(
  on arg: Arg.Type,
  returning values: [T],
  then value: T
) -> SpySync<T, Arg> {
  spySync(returning: values, then: value)
}

public func spy<T, Arg>(returning values: [T], then fallback: T? = nil) -> Spy<T, Arg> {
  let returns = ActorIsolated<[T]>(values)
  let invocations = ActorIsolated<[Arg]>([])
  let invoked = ActorIsolated(false)
  return .init(
    invocations: invocations,
    fn: { arg in
      let currentInvocations = await invocations.value
      await invocations.setValue(currentInvocations + [arg])
      await invoked.setValue(true)
      var current = await returns.value
      let returnValue: T
      if current.count > 0 {
        returnValue = current.removeFirst()
        let updated = current
        await returns.setValue(updated)
      } else if let fallback {
        returnValue = fallback
      } else {
        fatalError(
          "spy<\(String(reflecting: T.self)), \(String(reflecting: Arg.self))> called more than expected number of times \(values.count)"
        )
      }
      return returnValue
    }
  )
}

public func spySync<T, Arg>(returning values: [T], then fallback: T? = nil) -> SpySync<T, Arg> {
  let returns = LockIsolated<[T]>(values)
  let invocations = LockIsolated<[Arg]>([])
  let invoked = LockIsolated(false)
  return .init(
    invocations: invocations,
    fn: { arg in
      let currentInvocations = invocations.value
      invocations.setValue(currentInvocations + [arg])
      invoked.setValue(true)
      var current = returns.value
      let returnValue: T
      if current.count > 0 {
        returnValue = current.removeFirst()
        let updated = current
        returns.setValue(updated)
      } else if let fallback {
        returnValue = fallback
      } else {
        fatalError(
          "spy<\(String(reflecting: T.self)), \(String(reflecting: Arg.self))> called more than expected number of times \(values.count)"
        )
      }
      return returnValue
    }
  )
}

public func spy2<T, Arg1, Arg2>(
  on arg: (Arg1.Type, Arg2.Type),
  returning value: T
) -> Spy2<T, Arg1, Arg2> {
  spy2(returning: [], then: value)
}

public func spy2<T, Arg1, Arg2>(
  returning values: [T],
  then fallback: T? = nil
) -> Spy2<T, Arg1, Arg2> {
  let returns = ActorIsolated<[T]>(values)
  let invocations = ActorIsolated<[Both<Arg1, Arg2>]>([])
  return .init(
    invocations: invocations,
    fn: { arg1, arg2 in
      let currentInvocations = await invocations.value
      await invocations.setValue(currentInvocations + [Both(arg1, arg2)])
      var current = await returns.value
      let returnValue: T
      if current.count > 0 {
        returnValue = current.removeFirst()
        let updated = current
        await returns.setValue(updated)
      } else if let fallback {
        returnValue = fallback
      } else {
        let types = [T.self, Arg1.self, Arg2.self]
          .map(String.init(describing:))
          .joined(separator: ", ")
        fatalError("spy<\(types))> called more than expected number of times \(values.count)")
      }
      return returnValue
    }
  )
}

public func spy3<T, Arg1, Arg2, Arg3>(
  on arg: (Arg1.Type, Arg2.Type, Arg3.Type),
  returning value: T
) -> Spy3<T, Arg1, Arg2, Arg3> {
  spy3(returning: [], then: value)
}

public func spy3<T, Arg1, Arg2, Arg3>(
  returning values: [T],
  then fallback: T? = nil
) -> Spy3<T, Arg1, Arg2, Arg3> {
  let returns = ActorIsolated<[T]>(values)
  let invocations = ActorIsolated<[Three<Arg1, Arg2, Arg3>]>([])
  let invoked = ActorIsolated(false)
  return .init(
    invocations: invocations,
    fn: { arg1, arg2, arg3 in
      let currentInvocations = await invocations.value
      await invocations.setValue(currentInvocations + [Three(arg1, arg2, arg3)])
      await invoked.setValue(true)
      var current = await returns.value
      let returnValue: T
      if current.count > 0 {
        returnValue = current.removeFirst()
        let updated = current
        await returns.setValue(updated)
      } else if let fallback {
        returnValue = fallback
      } else {
        let types = [T.self, Arg1.self, Arg2.self, Arg3.self]
          .map(String.init(describing:))
          .joined(separator: ", ")
        fatalError("spy<\(types))> called more than expected number of times \(values.count)")
      }
      return returnValue
    }
  )
}
