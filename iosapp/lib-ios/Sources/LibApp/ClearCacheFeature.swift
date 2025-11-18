import ComposableArchitecture
import LibClients

@Reducer
public struct ClearCacheFeature {
  @ObservableState
  public struct State: Equatable {
    public var availableDiskSpaceInBytes: Int?
    public var bytesCleared: Int = 0
    public var startClearCache: Date?
    public var completed: Bool = false

    public init(
      availableDiskSpaceInBytes: Int? = nil,
      bytesCleared: Int = 0,
      startClearCache: Date? = nil,
      completed: Bool = false,
    ) {
      self.availableDiskSpaceInBytes = availableDiskSpaceInBytes
      self.bytesCleared = bytesCleared
      self.startClearCache = startClearCache
      self.completed = completed
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
    case completeBtnTapped
    case receivedClearCacheUpdate(DeviceClient.ClearCacheUpdate)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.startClearCache = self.deps.date.now
        let availableSpace = self.deps.device.availableDiskSpaceInBytes()
        state.availableDiskSpaceInBytes = availableSpace
        return .publisher { [deps = self.deps] in
          deps.device.clearCache(availableSpace)
            .map { .receivedClearCacheUpdate($0) }
            .receive(on: deps.mainQueue)
        }.cancellable(id: CancelId.cacheClearUpdates, cancelInFlight: true)

      case .receivedClearCacheUpdate(.bytesCleared(let bytes)):
        state.bytesCleared = bytes
        return .none

      case .receivedClearCacheUpdate(.finished):
        state.completed = true
        let diskSpace = state.availableDiskSpaceInBytes
          .map { Bytes.humanReadable($0) } ?? "unknown"
        return .merge(
          .run { [start = state.startClearCache, deps = self.deps] _ in
            if let start {
              let elapsed = String(format: "%.1f", deps.date.now.timeIntervalSince(start) / 60.0)
              await deps.api.logEvent(
                "cb9cf096",
                "cache cleared, elapsed time: \(elapsed)m, disk: \(diskSpace)",
              )
            } else {
              await deps.api.logEvent(
                "cb9cf096",
                "cache cleared, elapsed time: (unknown), disk: \(diskSpace)",
              )
            }
          },
          .cancel(id: CancelId.cacheClearUpdates),
        )

      case .receivedClearCacheUpdate(.errorCouldNotCreateDir):
        return .merge(
          .run { [deps = self.deps] _ in
            await deps.api.logEvent("ae941213", "error creating cache fill dir")
          },
          .cancel(id: CancelId.cacheClearUpdates),
        )

      case .receivedClearCacheUpdate:
        return .none

      case .completeBtnTapped:
        return .none // should be handled by parent reducer
      }
    }
  }
}
