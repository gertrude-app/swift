import ComposableArchitecture
import Foundation

public struct Mock<T, U> {
  public var fn: @Sendable () async -> T
  public var invocations: ActorIsolated<U>
  public var invoked: ActorIsolated<Bool>
}

public struct Spy<T, Arg> {
  public var fn: @Sendable (Arg) async -> T
  public var invocations: ActorIsolated<[Arg]>
  public var invoked: ActorIsolated<Bool>
}

public struct Spy2<T, Arg1, Arg2> {
  public var fn: @Sendable (Arg1, Arg2) async -> T
  public var invocations: ActorIsolated<[Both<Arg1, Arg2>]>
  public var invoked: ActorIsolated<Bool>
}

public struct Spy3<T, Arg1, Arg2, Arg3> {
  public var fn: @Sendable (Arg1, Arg2, Arg3) async -> T
  public var invocations: ActorIsolated<[Three<Arg1, Arg2, Arg3>]>
  public var invoked: ActorIsolated<Bool>
}

public struct ThrowingSpy<T, Arg> {
  public var fn: @Sendable (Arg) async throws -> T
  public var invocations: ActorIsolated<[Arg]>
  public var invoked: ActorIsolated<Bool>
}

public func mock<T>(once value: T) -> Mock<T, Int> {
  mock(returning: [value])
}

public func mock<T>(always value: T) -> Mock<T, Int> {
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

public func mock<T>(returning values: [T], then fallback: T? = nil) -> Mock<T, Int> {
  let returns = ActorIsolated<[T]>(values)
  let invocations = ActorIsolated(0)
  let invoked = ActorIsolated(false)
  return .init(fn: {
    let currentInvocations = await invocations.value
    await invocations.setValue(currentInvocations + 1)
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
        "mock<\(String(reflecting: T.self))> called more than expected number of times \(values.count)"
      )
    }
    return returnValue
  }, invocations: invocations, invoked: invoked)
}

public func succeed<T, Arg>(with value: T, capturing: Arg.Type) -> ThrowingSpy<T, Arg> {
  spy(returning: [], then: value)
}

public func spy<T, Arg>(returning values: [T], then fallback: T? = nil) -> ThrowingSpy<T, Arg> {
  let returns = ActorIsolated<[T]>(values)
  let invocations = ActorIsolated<[Arg]>([])
  let invoked = ActorIsolated(false)
  return .init(
    fn: { arg in
      let currentInvocations = await invocations.value
      await invocations.setValue(currentInvocations + [arg])
      await invoked.setValue(true)
      var current = await returns.value
      let returnValue: T
      if current.count > 1 {
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
    },
    invocations: invocations,
    invoked: invoked
  )
}

public func spy<T, Arg>(on arg: Arg.Type, returning value: T) -> Spy<T, Arg> {
  spy(returning: [], then: value)
}

public func spy<T, Arg>(returning values: [T], then fallback: T? = nil) -> Spy<T, Arg> {
  let returns = ActorIsolated<[T]>(values)
  let invocations = ActorIsolated<[Arg]>([])
  let invoked = ActorIsolated(false)
  return .init(
    fn: { arg in
      let currentInvocations = await invocations.value
      await invocations.setValue(currentInvocations + [arg])
      await invoked.setValue(true)
      var current = await returns.value
      let returnValue: T
      if current.count > 1 {
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
    },
    invocations: invocations,
    invoked: invoked
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
  let invoked = ActorIsolated(false)
  return .init(
    fn: { arg1, arg2 in
      let currentInvocations = await invocations.value
      await invocations.setValue(currentInvocations + [Both(arg1, arg2)])
      await invoked.setValue(true)
      var current = await returns.value
      let returnValue: T
      if current.count > 1 {
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
    },
    invocations: invocations,
    invoked: invoked
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
    fn: { arg1, arg2, arg3 in
      let currentInvocations = await invocations.value
      await invocations.setValue(currentInvocations + [Three(arg1, arg2, arg3)])
      await invoked.setValue(true)
      var current = await returns.value
      let returnValue: T
      if current.count > 1 {
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
    },
    invocations: invocations,
    invoked: invoked
  )
}
