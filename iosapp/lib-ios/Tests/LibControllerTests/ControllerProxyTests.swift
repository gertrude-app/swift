import ConcurrencyExtras
import Dependencies
import GertieIOS
import LibCore
import NetworkExtension
import XCTest
import XExpect

@testable import LibController

final class ControllerProxyTests: XCTestCase {
  @MainActor
  func testStartFilterHeartbeat() async {
    let testClock = TestClock()
    let savedRules = LockIsolated<[Both<String, ProtectionMode>]>([])
    let fetchRules = LockIsolated(0)
    let notifyRulesChanged = LockIsolated(0)
    let vendorId = UUID()

    let proxy = withDependencies {
      $0.osLog = .noop
      $0.device.vendorId = { vendorId }
      $0.suspendingClock = testClock
      $0.api.logEvent = { @Sendable _, _ in }
      $0.api.fetchBlockRules = { @Sendable vid, blockGroups in
        precondition(vid == vendorId)
        precondition(blockGroups == [.whatsAppFeatures])
        fetchRules.withValue { $0 += 1 }
        return [.bundleIdContains("bad"), .bundleIdContains("bad2")]
      }
      $0.storage.loadData = { @Sendable key in
        if key == .protectionModeStorageKey {
          try! JSONEncoder().encode(ProtectionMode.normal([.bundleIdContains("bad")]))
        } else if key == .disabledBlockGroupsStorageKey {
          try! JSONEncoder().encode([BlockGroup.whatsAppFeatures])
        } else {
          fatalError("unexpected key: \(key)")
        }
      }
      $0.storage.saveCodable = { @Sendable value, key in
        savedRules.withValue { $0.append(.init(key, value as! ProtectionMode)) }
      }
    } operation: {
      ControllerProxy()
    }

    proxy.notifyRulesChanged.setValue { notifyRulesChanged.withValue { $0 += 1 } }
    proxy.startFilter()
    proxy.startHeartbeat(initialDelay: .seconds(60), interval: .minutes(5))
    await Task.megaYield()

    // fetches rules and writes updated rules to disk right away
    expect(fetchRules.value).toEqual(1)
    expect(notifyRulesChanged.value).toEqual(1)
    let saved = Both<String, ProtectionMode>(
      .protectionModeStorageKey,
      .normal([.bundleIdContains("bad"), .bundleIdContains("bad2")])
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

  @MainActor
  func testEmitsLogOnHandleNewFlow() async {
    let logEvent = LockIsolated(0)
    let proxy = withDependencies {
      $0.osLog = .noop
      $0.api.logEvent = { @Sendable id, detail in
        logEvent.withValue { $0 += 1 }
      }
    } operation: {
      ControllerProxy()
    }

    expect(logEvent.value).toEqual(0)
    let task = proxy.handleNewFlow(NEFilterFlow())
    await task.value
    expect(logEvent.value).toEqual(1)
  }

  @MainActor
  func testEmitsLogOnStopFilter() async {
    let logEvent = LockIsolated(0)
    let proxy = withDependencies {
      $0.osLog = .noop
      $0.api.logEvent = { @Sendable id, detail in
        logEvent.withValue { $0 += 1 }
      }
    } operation: {
      ControllerProxy()
    }
    expect(logEvent.value).toEqual(0)
    let task = proxy.stopFilter(reason: .userInitiated)
    await task.value
    expect(logEvent.value).toEqual(1)
  }
}

public struct Both<A: Equatable & Sendable, B: Equatable & Sendable>: Equatable, Sendable {
  public var a: A
  public var b: B
  public init(_ a: A, _ b: B) {
    self.a = a
    self.b = b
  }
}
