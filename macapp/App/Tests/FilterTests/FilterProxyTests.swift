import ConcurrencyExtras
import Core
import Dependencies
import NetworkExtension
import TestSupport
import XCTest
import XExpect

@testable import Filter

final class FilterProxyTests: XCTestCase {
  func testEarlyDecisionBlockBecomesDropWithNoLog() {
    let proxy = FilterProxy(earlyDecision: .block(.missingUserId))
    let verdict = proxy.handleNewFlow(.mock)
    expect(verdict.isDrop).toBeTrue()
    // this is current behavior, but i'm not certain we don't want to log here
    // as i'm not sure if this ever happens in practice
    expect(proxy.store.state.logs.bundleIds).toEqual([:]) // <-- not logged
  }

  func testEarlyDecisionAllowBecomesAllowWithNoLog() {
    let proxy = FilterProxy(earlyDecision: .allow(.systemUser(501)))
    let verdict = proxy.handleNewFlow(.mock)
    expect(verdict.isDrop).toBeFalse()
    expect(proxy.store.state.logs.bundleIds).toEqual([:]) // current behavior
  }

  func testEarlyDecisionAllowingGertrudeDuringDowntime() {
    let proxy = FilterProxy(earlyDecision: .blockDuringDowntime(501))
    let verdict = proxy.handleNewFlow(.gertrude)
    expect(verdict.isDrop).toBeFalse()
    expect(proxy.store.state.logs.bundleIds).toEqual([:])
  }

  func testEarlyDecisionAllowingSystemUIServerInternalDuringDowntime() {
    let proxy = FilterProxy(earlyDecision: .blockDuringDowntime(501))
    let verdict = proxy.handleNewFlow(.init(description: """
      sourceAppIdentifier = .com.apple.systemuiserver
      remoteEndpoint = 192.168.0.1:8080
    """))
    expect(verdict.isDrop).toBeFalse()
    expect(proxy.store.state.logs.bundleIds).toEqual([:])
  }

  func testEarlyDecisionBlockingDuringDowntime() {
    let proxy = FilterProxy(earlyDecision: .blockDuringDowntime(501))
    let verdict = proxy.handleNewFlow(.mock)
    expect(verdict.isDrop).toBeTrue()
    expect(proxy.store.state.logs.bundleIds).toEqual([:]) // current behavior
  }

  func testBlockedNewFlowWithoutPeekingBytesDropsAndLogs() {
    let proxy = FilterProxy(
      earlyDecision: .none(501),
      flowDecision: .block(.defaultNotAllowed)
    )
    let verdict = proxy.handleNewFlow(.mock)
    expect(verdict.isDrop).toBeTrue()
    expect(proxy.store.state.logs.bundleIds).toEqual(["com.acme.app": 1])
  }

  @MainActor
  func testBlockedNewFlowSendsDecisionIfSending() async {
    let sent = LockIsolated<[String]>([])
    await withDependencies {
      $0.filterExtension.version = { "2.6.0" }
      $0.date = .constant(.init(timeIntervalSinceReferenceDate: 0))
      $0.uuid = .incrementing
      $0.xpc.sendBlockedRequest = { _, req in
        sent.withValue { $0.append(req.app.bundleId) }
      }
    } operation: {
      let proxy = FilterProxy(
        earlyDecision: .none(501),
        flowDecision: .block(.defaultNotAllowed)
      ) {
        $0.blockListeners[501] = .distantFuture
      }
      proxy.sendingBlockDecisions = true // <-- sending decisions
      let verdict = proxy.handleNewFlow(.mock)
      expect(verdict.isDrop).toBeTrue()
      await Task.megaYield()
      expect(sent.value).toEqual(["com.acme.app"])
    }
  }

  func testAllowedNewFlowWithoutPeekingBytesAllowsAndLogs() {
    let proxy = FilterProxy(
      earlyDecision: .none(501),
      flowDecision: .allow(.permittedByKey(.init()))
    )
    let verdict = proxy.handleNewFlow(.mock)
    expect(verdict.isDrop).toBeFalse()
    expect(proxy.store.state.logs.bundleIds).toEqual(["com.acme.app": 1])
  }

  func testDeferredNewFlowLogsAndSetsUserId() {
    let proxy = FilterProxy(flowDecision: .some(.none))
    let flow = NEFilterFlow.DTO.mock
    let verdict = proxy.handleNewFlow(flow)
    expect(verdict.isExamineBytes).toBeTrue()
    expect(proxy.flowUserIds[flow.identifier]).toEqual(501)
    expect(proxy.store.state.logs.bundleIds).toEqual(["com.acme.app": 1])
  }

  func testOutboundFlowDecisionBlock() {
    let proxy = FilterProxy(flowDecision: .block(.defaultNotAllowed))
    let flow = NEFilterFlow.DTO.mock
    proxy.flowUserIds[flow.identifier] = 501

    let verdict = proxy.handleOutboundData(from: flow, readBytes: .init())
    expect(verdict.isDrop).toBeTrue()
    expect(proxy.flowUserIds).toEqual([:]) // removes the flow
  }

  func testOutboundFlowDecisionAllow() {
    let proxy = FilterProxy(flowDecision: .allow(.permittedByKey(.init())))
    let flow = NEFilterFlow.DTO.mock
    proxy.flowUserIds[flow.identifier] = 501

    let verdict = proxy.handleOutboundData(from: flow, readBytes: .init())
    expect(verdict.isDrop).toBeFalse()
    expect(proxy.flowUserIds).toEqual([:]) // removes the flow
  }

  @MainActor
  func testBlockedDataFlowSendsDecisionIfSending() async {
    let sent = LockIsolated<[String]>([])
    await withDependencies {
      $0.filterExtension.version = { "2.6.0" }
      $0.date = .constant(.init(timeIntervalSinceReferenceDate: 0))
      $0.uuid = .incrementing
      $0.xpc.sendBlockedRequest = { _, req in
        sent.withValue { $0.append(req.app.bundleId) }
      }
    } operation: {
      let proxy = FilterProxy(flowDecision: .block(.defaultNotAllowed)) {
        $0.blockListeners[501] = .distantFuture
      }
      let flow = NEFilterFlow.DTO.mock
      proxy.flowUserIds[flow.identifier] = 501
      proxy.sendingBlockDecisions = true // <-- sending decisions
      let verdict = proxy.handleOutboundData(from: flow, readBytes: .init())
      expect(verdict.isDrop).toBeTrue()
      await Task.megaYield()
      expect(sent.value).toEqual(["com.acme.app"])
    }
  }
}

// helpers

extension NEFilterFlow.DTO {
  static var mock: Self {
    .init(description: "sourceAppIdentifier = com.acme.app")
  }

  static var gertrude: Self {
    .init(description: "sourceAppIdentifier = com.netrivet.gertrude.app")
  }
}

extension FilterProxy {
  convenience init(
    earlyDecision: FilterDecision.FromUserId = .none(501),
    flowDecision: FilterDecision.FromFlow?? = .some(.some(.block(.defaultNotAllowed))),
    config: (inout Filter.State) -> Void = { _ in }
  ) {
    var state = Filter.State()
    config(&state)
    self.init(store: .init(initialState: state))
    self.store.__TEST_MOCK_EARLY_DECISION = earlyDecision
    self.store.__TEST_MOCK_FLOW_DECISION = flowDecision
  }
}

extension NEFilterDataVerdict {
  var isDrop: Bool {
    self.description.contains("drop = YES")
  }
}

extension NEFilterNewFlowVerdict {
  var isDrop: Bool {
    self.description.contains("drop = YES")
  }

  var isExamineBytes: Bool {
    !self.isDrop && self.description.contains("filterOutbound = YES")
  }
}
