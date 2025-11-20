import ComposableArchitecture
import IOSRoute
import LibClients

@Reducer
public struct InfoFeature {
  @ObservableState
  public struct State: Equatable, Sendable {
    public var connection: ChildIOSDeviceData?
    public var vendorId: UUID?
    public var numRules: Int = 0
    public var numDisabledBlockGroups: Int = 0
    public var timesShaken: Int = 0
    public var subScreen: SubScreen = .main
    public var clearCache: ClearCacheFeature.State?

    public init(
      connection: ChildIOSDeviceData? = nil,
      vendorId: UUID? = nil,
      numRules: Int = 0,
      numDisabledBlockGroups: Int = 0,
      subScreen: SubScreen = .main,
    ) {
      self.connection = connection
      self.vendorId = vendorId
      self.numRules = numRules
      self.numDisabledBlockGroups = numDisabledBlockGroups
      self.subScreen = subScreen
    }
  }

  public init() {
    self.deps.osLog.setPrefix("APP INFO FEATURE")
  }

  public enum SubScreen: Sendable, Equatable {
    case main
    case explainClearCache1
    case explainClearCache2
    case clearingCache
  }

  public enum Action: Equatable {
    case sheetPresented
    case receivedShake
    case clearCacheTapped
    case explainClearCacheNextTapped
    case cancelClearCacheTapped
    case clearCache(ClearCacheFeature.Action)
  }

  struct Deps: Sendable {
    @Dependency(\.api) var api
    @Dependency(\.device) var device
    @Dependency(\.sharedStorage) var sharedStorage
    @Dependency(\.systemExtension) var systemExtension
    @Dependency(\.filter) var filter
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.osLog) var osLog
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.continuousClock) var clock
  }

  enum CancelId {
    case cacheClearUpdates
  }

  @ObservationIgnored
  let deps = Deps()

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .sheetPresented:
        state.subScreen = .main
        return .run { [state, deps = self.deps] _ in
          deps.osLog.log("Info appear vendor id: \(state.vendorId?.uuidString ?? "(nil)")")
          if let connection = state.connection {
            try await deps.refreshConnectedState(connection: connection)
          } else {
            try await deps.ensureUnconnectedRules(vendorId: state.vendorId)
            try await deps.filter.send(notification: .rulesChanged)
          }
        }

      case .clearCacheTapped:
        state.subScreen = .explainClearCache1
        return .none

      case .cancelClearCacheTapped:
        state.clearCache = nil
        state.subScreen = .main
        return .none

      case .explainClearCacheNextTapped where state.subScreen == .explainClearCache1:
        state.subScreen = .explainClearCache2
        return .none

      case .explainClearCacheNextTapped where state.subScreen == .explainClearCache2:
        state.subScreen = .clearingCache
        state.clearCache = .init(context: .info)
        return .none

      case .explainClearCacheNextTapped:
        state.subScreen = .main
        return .run { [deps = self.deps] _ in
          await deps.api.logEvent("e81796af", "UNEXPECTED")
        }

      case .receivedShake where state.connection == nil && state.timesShaken == 5:
        self.deps.osLog.log("received 5th shake: entering unconnected recovery mode")
        state.timesShaken = 0
        return self.unconnectedRecovery()

      case .receivedShake where state.connection != nil && state.timesShaken == 5:
        self.deps.osLog.log("received 5th shake: entering connected recovery mode")
        state.timesShaken = 0
        return .run { [deps = self.deps] _ in
          await deps.sendRecoveryDirective()
          await deps.dismiss()
        }

      case .receivedShake:
        self.deps.osLog.log("received shake \(state.timesShaken + 1)")
        state.timesShaken += 1
        return .none

      case .clearCache(.completeBtnTapped),
           .clearCache(.receivedClearCacheUpdate(.errorCouldNotCreateDir)):
        state.clearCache = nil
        state.subScreen = .main
        return .none

      case .clearCache:
        return .none
      }
    }
    .ifLet(\.clearCache, action: \.clearCache) {
      ClearCacheFeature()
    }
  }

  func unconnectedRecovery() -> Effect<Action> {
    .run { [deps = self.deps] _ in
      await deps.api.logEvent("a8998540", "entering recovery mode")
      if deps.sharedStorage.loadDisabledBlockGroups() == nil {
        deps.osLog.log("unconnected recovery: no stored disabled block groups, saving empty")
        deps.sharedStorage.saveDisabledBlockGroups([])
      } else {
        deps.osLog.log("unconnected recovery: disabled block groups already stored")
      }
      let rules = deps.sharedStorage.loadProtectionMode()
      deps.osLog.log("unconnected recovery: current rules: \(rules?.shortDesc ?? "(nil)")")
      if rules.missingRules {
        deps.osLog.log("unconnected recovery: rules missing, fetching defaults")
        await deps.api.logEvent("bcca235f", "rules missing in recovery mode")
        let defaultRules = try? await deps.api
          .fetchDefaultBlockRules(deps.device.vendorId())
        if let defaultRules, !defaultRules.isEmpty {
          deps.sharedStorage.saveProtectionMode(.normal(defaultRules))
          deps.osLog.log("unconnected recovery: saved fetched default rules")
        } else {
          await deps.api.logEvent("2c3a4481", "failed to fetch defaults in recovery mode")
          deps.sharedStorage
            .saveProtectionMode(.normal(BlockRule.Legacy.defaults.map(\.current)))
          deps.osLog.log("unconnected recovery: saved hardcoded default fallback rules")
        }
      }
      deps.osLog.log("unconnected recovery: sending rules changed notification")
      try await deps.filter.send(notification: .rulesChanged)
      deps.osLog.log("unconnected recovery: sending recovery directive")
      await deps.sendRecoveryDirective()
      deps.osLog.log("unconnected recovery: dismissing info screen")
      await deps.dismiss()
    }
  }
}

extension InfoFeature.Deps {
  func ensureUnconnectedRules(vendorId: UUID?) async throws {
    let disabled = self.sharedStorage.loadDisabledBlockGroups()
    if disabled == nil {
      await self.api.logEvent("59d3c6d1", "UNEXPECTED no stored disabled block groups")
      self.sharedStorage.saveDisabledBlockGroups([])
    }
    guard let vendorId else { return }
    let rules = try await self.api.fetchBlockRules(
      vendorId: vendorId,
      disabledGroups: disabled ?? [],
    )
    self.sharedStorage.saveProtectionMode(.normal(rules))
  }

  func refreshConnectedState(connection: ChildIOSDeviceData) async throws {
    self.osLog.log("InfoFeature child id: \(connection.childId)")
    let before = self.sharedStorage.loadProtectionMode()
    self.osLog.log("InfoFeature connected rules before refresh: \(before?.shortDesc ?? "(nil)")")
    try await self.filter.send(notification: .refreshRules)
    try await self.clock.sleep(for: .seconds(2)) // time for api request, save rules
    let after = self.sharedStorage.loadProtectionMode()
    self.osLog.log("InfoFeature connected rules after refresh: \(after?.shortDesc ?? "(nil)")")
  }

  func sendRecoveryDirective() async {
    let directive = try? await self.api.recoveryDirective()
    if directive == "retry" {
      await self.systemExtension.cleanupForRetry()
      await self.api.logEvent("aeaa467d", "received retry directive")
    }
  }
}
