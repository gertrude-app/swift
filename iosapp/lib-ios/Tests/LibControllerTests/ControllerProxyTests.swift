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
    let sendFilterErrors = LockIsolated(0)
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
      $0.filter.notifyRulesChanged = {
        notifyRulesChanged.withValue { $0 += 1 }
      }
      $0.filter.sendFilterErrors = {
        sendFilterErrors.withValue { $0 += 1 }
      }
    } operation: {
      let controllerProxy = ControllerProxy()
      controllerProxy.startFilter()

      await testClock.advance(by: .minutes(59))
      expect(fetchRules.value).toEqual(0)
      await testClock.advance(by: .minutes(2))

      expect(sendFilterErrors.value).toEqual(1)
      expect(fetchRules.value).toEqual(1)
      expect(notifyRulesChanged.value).toEqual(1)
      expect(savedRules.value).toEqual([.init(
        .blockRulesStorageKey,
        [.bundleIdContains("bad"), .bundleIdContains("bad2")]
      )])

      await testClock.advance(by: .minutes(60))
      expect(sendFilterErrors.value).toEqual(2)
      expect(fetchRules.value).toEqual(2)
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
