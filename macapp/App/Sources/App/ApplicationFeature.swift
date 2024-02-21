import ComposableArchitecture
import Foundation

// public, not nested, because it's used in the AppDelegate
public enum ApplicationAction: Equatable, Sendable {
  case didFinishLaunching
  case willSleep
  case didWake
  case willTerminate
}

enum ApplicationFeature {
  typealias Action = ApplicationAction

  struct RootReducer {
    @Dependency(\.app) var app
    @Dependency(\.backgroundQueue) var bgQueue
    @Dependency(\.device) var device
    @Dependency(\.storage) var storage
    @Dependency(\.filterXpc) var filterXpc
    @Dependency(\.filterExtension) var filterExtension
    @Dependency(\.mainQueue) var mainQueue
  }
}

extension ApplicationFeature.RootReducer: RootReducing {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .application(.didFinishLaunching):
      // let socket = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
      // print("jared: app create socket \(socket)")
      // if let myUrl = FileManager.default
      //   .containerURL(
      //     forSecurityApplicationGroupIdentifier: "WFN83LM943.com.netrivet.gertrude.group"
      //   ) {
      //   print("jared: app container url \(myUrl)")
      // } else {
      //   print("jared: app container url nil")
      // }
      // let socketPath =
      //   URL(
      //     fileURLWithPath: "file:///private/var/root/Library/Group Containers/WFN83LM943.com.netrivet.gertrude.group"
      //   )
      //   .appendingPathComponent("GertrudeUDS").path

      // var address = sockaddr_un()
      // address.sun_family = sa_family_t(AF_UNIX)
      // socketPath.withCString { ptr in
      //   withUnsafeMutablePointer(to: &address.sun_path.0) { dest in
      //     _ = strcpy(dest, ptr)
      //   }
      // }

      // print("jared: Binding to socket path: \(socketPath)")
      // if Darwin.bind(
      //   socket,
      //   withUnsafePointer(to: &address) {
      //     $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { $0 }
      //   },
      //   socklen_t(MemoryLayout<sockaddr_un>.size)
      // ) == -1 {
      //   print("jared: Error binding socket - \(String(cString: strerror(errno)))")
      // } else {
      //   print("jared: Bound socket")
      // }

      return .merge(
        .exec { send in
          #if DEBUG
            // uncomment to test ONBOARDING
            // if ProcessInfo.processInfo.environment["SWIFT_DETERMINISTIC_HASHING"] == nil {
            //   await storage.deleteAll()
            // }
          #endif
          await send(.loadedPersistentState(try await storage.loadPersistentState()))
        },

        .exec { send in
          let setupState = await filterExtension.setup()
          await send(.filter(.receivedState(setupState)))
          if setupState.installed {
            _ = await filterXpc.establishConnection()
          }
        },

        .publisher {
          filterExtension.stateChanges()
            .map { .filter(.receivedState($0)) }
            .receive(on: mainQueue)
        },

        .publisher {
          filterXpc.events()
            .map { .xpc($0) }
            .receive(on: mainQueue)
        }
      )

    case .application(.willTerminate):
      return .merge(
        .cancel(id: AppReducer.CancelId.heartbeatInterval),
        .cancel(id: AppReducer.CancelId.websocketMessages)
      )

    default:
      return .none
    }
  }
}

func heartbeatIntervals(for tick: Int) -> [HeartbeatInterval] {
  var intervals: [HeartbeatInterval] = [.everyMinute]
  if tick % 5 == 0 {
    intervals.append(.everyFiveMinutes)
  }
  if tick % 20 == 0 {
    intervals.append(.everyTwentyMinutes)
  }
  if tick % 60 == 0 {
    intervals.append(.everyHour)
  }
  if tick % 360 == 0 {
    intervals.append(.everySixHours)
  }
  return intervals
}
