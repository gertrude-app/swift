import ComposableArchitecture
import LibClients

@Reducer
public struct ClearCacheFeature {
  @ObservableState
  public struct State: Equatable, Sendable {
    public var screen: Screen = .loading
    public var availableDiskSpaceInBytes: Int?
    public var batteryLevel: DeviceClient.BatteryLevel = .unknown
    public var bytesCleared: Int = 0
    public var startClearCache: Date?
    public var context: Context

    var logContext: String {
      "(context: \(self.context))"
    }

    public enum Screen: Equatable, Sendable {
      case loading
      case batteryWarning
      case clearing
      case cleared
    }

    public enum Context: String, Equatable, Sendable {
      case onboarding
      case info
    }

    public init(
      context: Context,
      screen: Screen = .loading,
      availableDiskSpaceInBytes: Int? = nil,
      batteryLevel: DeviceClient.BatteryLevel = .unknown,
      bytesCleared: Int = 0,
      startClearCache: Date? = nil,
    ) {
      self.context = context
      self.screen = screen
      self.availableDiskSpaceInBytes = availableDiskSpaceInBytes
      self.batteryLevel = batteryLevel
      self.bytesCleared = bytesCleared
      self.startClearCache = startClearCache
    }
  }

  public init() {}

  struct Deps: Sendable {
    @Dependency(\.api) var api
    @Dependency(\.date) var date
    @Dependency(\.device) var device
    @Dependency(\.mainQueue) var mainQueue
  }

  @ObservationIgnored
  let deps = Deps()

  enum CancelId {
    case cacheClearUpdates
  }

  public enum Action: Equatable {
    case onAppear
    case batteryWarningContinueTapped
    case completeBtnTapped
    case receivedClearCacheUpdate(DeviceClient.ClearCacheUpdate)
    case receivedDeviceInfo(batteryLevel: DeviceClient.BatteryLevel, availableSpace: Int?)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .run { [deps = self.deps] send in
          await send(.receivedDeviceInfo(
            batteryLevel: deps.device.batteryLevel(),
            availableSpace: deps.device.availableDiskSpaceInBytes(),
          ))
        }

      case .receivedDeviceInfo(let batteryLevel, let availableSpace):
        state.batteryLevel = batteryLevel
        state.availableDiskSpaceInBytes = availableSpace
        if batteryLevel.isLow || availableSpace ?? 0 > (Bytes.inGigabyte * 60) {
          state.screen = .batteryWarning
          return .none
        } else {
          return self.startCacheClear(&state)
        }

      case .batteryWarningContinueTapped:
        return self.startCacheClear(&state)

      case .receivedClearCacheUpdate(.bytesCleared(let bytes)):
        state.bytesCleared = bytes
        return .none

      case .receivedClearCacheUpdate(.finished):
        state.screen = .cleared
        let diskSpace = state.availableDiskSpaceInBytes
          .map { Bytes.humanReadable($0) } ?? "unknown"
        return .merge(
          .run { [start = state.startClearCache, deps = self.deps, ctx = state.context] _ in
            if let start {
              let elapsed = String(format: "%.1f", deps.date.now.timeIntervalSince(start) / 60.0)
              await deps.api.logEvent(
                "cb9cf096",
                "cache cleared, elapsed time: \(elapsed)m, disk: \(diskSpace) \(ctx)",
              )
            } else {
              await deps.api.logEvent(
                "cb9cf096",
                "cache cleared, elapsed time: (unknown), disk: \(diskSpace) \(ctx)",
              )
            }
          },
          .cancel(id: CancelId.cacheClearUpdates),
        )

      case .receivedClearCacheUpdate(.errorCouldNotCreateDir):
        return .merge(
          .run { [deps = self.deps, ctx = state.context] _ in
            await deps.api.logEvent("ae941213", "error creating cache fill dir \(ctx)")
          },
          .cancel(id: CancelId.cacheClearUpdates),
        )

      // should be handled by parent reducer
      case .completeBtnTapped:
        return .none
      }
    }
  }

  func startCacheClear(_ state: inout State) -> Effect<Action> {
    state.screen = .clearing
    state.startClearCache = self.deps.date.now
    let availableSpace = state.availableDiskSpaceInBytes
    return .merge(
      .run { [deps = self.deps, ctx = state.context] _ in
        let humanSize = Bytes.humanReadable(availableSpace ?? -1, decimalPlaces: 1, prefix: .binary)
        await deps.api.logEvent("ea3f9c37", "starting cache clear, disk size: \(humanSize), \(ctx)")
      },
      .publisher { [deps = self.deps] in
        deps.device.clearCache(availableSpace)
          .map { .receivedClearCacheUpdate($0) }
          .receive(on: deps.mainQueue)
      }.cancellable(id: CancelId.cacheClearUpdates, cancelInFlight: true),
    )
  }
}
