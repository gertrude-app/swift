import ConcurrencyExtras
import Dependencies
import GertieIOS
import NetworkExtension
import XCTest
import XExpect

@testable import LibController

final class ControllerProxyTests: XCTestCase {
  func testStartFilterHeartbeat() async {
    let testClock = TestClock()
    let savedRules = LockIsolated<[Both<String, [BlockRule]>]>([])
    let fetchRules = LockIsolated(0)
    let notifyRulesChanged = LockIsolated(0)
    await withDependencies {
      $0.suspendingClock = testClock
      $0.api.fetchBlockRules = {
        fetchRules.withValue { $0 += 1 }
        return [.bundleIdContains("bad"), .bundleIdContains("bad2")]
      }
      $0.storage.loadData = { @Sendable _ in
        try! JSONEncoder().encode([BlockRule.bundleIdContains("bad")])
      }
      $0.storage.saveCodable = { @Sendable value, key in
        savedRules.withValue { $0.append(.init(key, value as! [BlockRule])) }
      }
    } operation: {
      let controllerProxy = ControllerProxy()
      controllerProxy.notifyRulesChanged = { notifyRulesChanged.withValue { $0 += 1 } }
      controllerProxy.startFilter()
      await Task.megaYield()

      // fetches rules and writes updated rules to disk right away
      expect(fetchRules.value).toEqual(1)
      expect(notifyRulesChanged.value).toEqual(1)
      let saved = Both<String, [BlockRule]>.init(
        .blockRulesStorageKey,
        [.bundleIdContains("bad"), .bundleIdContains("bad2")]
      )
      expect(savedRules.value).toEqual([saved])

      // and fetches again after one minute...
      await testClock.advance(by: .minutes(1))
      expect(fetchRules.value).toEqual(2)
      expect(notifyRulesChanged.value).toEqual(2)
      expect(savedRules.value).toEqual([saved, saved])

      // ...before starting the looping heartbeat
      await testClock.advance(by: .minutes(4))
      expect(fetchRules.value).toEqual(2) // <-- still 2
      await testClock.advance(by: .minutes(2))
      expect(fetchRules.value).toEqual(3)
      expect(notifyRulesChanged.value).toEqual(3)
      expect(savedRules.value).toEqual([saved, saved, saved])

      // once more after 5 minutes
      await testClock.advance(by: .minutes(5))
      expect(fetchRules.value).toEqual(4)
      expect(notifyRulesChanged.value).toEqual(4)
      expect(savedRules.value).toEqual([saved, saved, saved, saved])
    }
  }

  func testEmitsLogOnHandleNewFlow() async {
    let logEvent = LockIsolated(0)
    await withDependencies {
      $0.api.logEvent = { @Sendable id, detail in
        logEvent.withValue { $0 += 1 }
      }
    } operation: {
      let controllerProxy = ControllerProxy()
      expect(logEvent.value).toEqual(0)
      let task = controllerProxy.handleNewFlow(NEFilterFlow())
      await task.value
      expect(logEvent.value).toEqual(1)
    }
  }

  func testEmitsLogOnStopFilter() async {
    let logEvent = LockIsolated(0)
    await withDependencies {
      $0.api.logEvent = { @Sendable id, detail in
        logEvent.withValue { $0 += 1 }
      }
    } operation: {
      let controllerProxy = ControllerProxy()
      expect(logEvent.value).toEqual(0)
      let task = controllerProxy.stopFilter(reason: .userInitiated)
      await task.value
      expect(logEvent.value).toEqual(1)
    }
  }
}

public struct Both<A: Equatable, B: Equatable>: Equatable {
  public var a: A
  public var b: B
  public init(_ a: A, _ b: B) {
    self.a = a
    self.b = b
  }
}
