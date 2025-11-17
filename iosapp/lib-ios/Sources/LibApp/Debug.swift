import ComposableArchitecture
import IOSRoute

@Reducer
public struct Debug {
  @ObservableState
  public struct State: Equatable, Sendable {
    public var connection: ChildIOSDeviceData_b1?
    public var vendorId: UUID?
    public var timesShaken: Int = 0

    public init(
      connection: ChildIOSDeviceData_b1? = nil,
      vendorId: UUID? = nil,
      timesShaken: Int = 0,
    ) {
      self.connection = connection
      self.vendorId = vendorId
      self.timesShaken = timesShaken
    }
  }

  public init() {
    self.deps.osLog.setPrefix("APP DEBUG")
  }

  public enum Action: Equatable {
    case sheetPresented
    case receivedShake
    case setData(connection: ChildIOSDeviceData_b1?, vendorId: UUID?)
  }

  struct Deps: Sendable {
    @Dependency(\.api) var api
    @Dependency(\.device) var device
    @Dependency(\.sharedStorage) var sharedStorage
    @Dependency(\.systemExtension) var systemExtension
    @Dependency(\.filter) var filter
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.osLog) var osLog
  }

  @ObservationIgnored
  let deps = Deps()

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .sheetPresented:
        return .run { [deps = self.deps] send in
          let vendorId = await deps.device.vendorId()
          let connection = deps.sharedStorage.loadAccountConnection()
          await send(.setData(connection: connection, vendorId: vendorId))
          deps.osLog.log("SHAKE vendor id: \(vendorId?.uuidString ?? "(nil)")")
          if let connection {
            try await deps.refreshConnectedState(connection: connection)
          } else {
            try await deps.ensureUnconnectedRules(vendorId: vendorId)
            try await deps.filter.send(notification: .rulesChanged)
          }
        }
      case .receivedShake where state.connection == nil && state.timesShaken == 5:
        state.timesShaken = 0
        return .run { [deps = self.deps] send in
          await deps.api.logEvent("a8998540", "entering recovery mode")
          if deps.sharedStorage.loadDisabledBlockGroups() == nil {
            deps.sharedStorage.saveDisabledBlockGroups([])
          }
          let rules = deps.sharedStorage.loadProtectionMode()
          if rules.missingRules {
            await deps.api.logEvent("bcca235f", "rules missing in recovery mode")
            let defaultRules = try? await deps.api
              .fetchDefaultBlockRules(deps.device.vendorId())
            if let defaultRules, !defaultRules.isEmpty {
              deps.sharedStorage.saveProtectionMode(.normal(defaultRules))
            } else {
              await deps.api.logEvent("2c3a4481", "failed to fetch defaults in recovery mode")
              deps.sharedStorage
                .saveProtectionMode(.normal(BlockRule.Legacy.defaults.map(\.current)))
            }
          }
          try await deps.filter.send(notification: .rulesChanged)
          await deps.sendRecoveryDirective()
          await deps.dismiss()
        }
      case .receivedShake where state.connection != nil && state.timesShaken == 5:
        state.timesShaken = 0
        return .run { [deps = self.deps] send in
          await deps.sendRecoveryDirective()
          await deps.dismiss()
        }
      case .receivedShake:
        state.timesShaken += 1
        return .none
      case .setData(let connection, let vendorId):
        state.connection = connection
        state.vendorId = vendorId
        return .none
      }
    }
  }
}

extension Debug.Deps {
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

  func refreshConnectedState(connection: ChildIOSDeviceData_b1) async throws {
    self.osLog.log("SHAKE child id: \(connection.childId)")
    self.osLog.log("SHAKE device id: \(connection.deviceId)")
    let before = self.sharedStorage.loadProtectionMode()
    self.osLog.log("SHAKE connected rules before refresh: \(before?.shortDesc ?? "(nil)")")
    try await self.filter.send(notification: .refreshRules)
    let after = self.sharedStorage.loadProtectionMode()
    self.osLog.log("SHAKE connected rules after refresh: \(after?.shortDesc ?? "(nil)")")
  }

  func sendRecoveryDirective() async {
    let directive = try? await self.api.recoveryDirective()
    if directive == "retry" {
      await self.systemExtension.cleanupForRetry()
      await self.api.logEvent("aeaa467d", "received retry directive")
    }
  }
}
