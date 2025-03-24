import ComposableArchitecture
import Foundation

enum MenuBarFeature: Feature {
  struct State: Equatable {
    var dropdownOpen = false
  }

  enum Action: Equatable, Decodable, Sendable {
    case menuBarIconClicked
    case resumeFilterClicked
    case suspendFilterClicked
    case refreshRulesClicked
    case administrateClicked
    case viewNetworkTrafficClicked
    case connectClicked
    case connectSubmit(code: Int)
    case retryConnectClicked
    case removeFilterClicked
    case connectFailedHelpClicked
    case welcomeAdminClicked
    case turnOnFilterClicked
    case updateNagDismissClicked
    case updateNagUpdateClicked
    case updateRequiredUpdateClicked
    case quitForNowClicked
    case quitForUninstallClicked
    case pauseDowntimeClicked(duration: DowntimePauseDuration)
    case resumeDowntimeClicked

    enum DowntimePauseDuration: String, Equatable, Codable, Sendable {
      case tenMinutes
      case oneHour
      case oneDay
    }
  }

  struct Reducer: FeatureReducer {
    @Dependency(\.device) var device
  }

  struct RootReducer: AdminAuthenticating {
    typealias Action = AppReducer.Action
    typealias State = AppReducer.State
    @Dependency(\.api) var api
    @Dependency(\.app) var app
    @Dependency(\.filterXpc) var xpc
    @Dependency(\.filterExtension) var filter
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.storage) var storage
    @Dependency(\.security) var security
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar
  }
}

extension MenuBarFeature.Reducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .menuBarIconClicked:
      state.dropdownOpen.toggle()
      return .none

    // get menu bar out of the way after certain actions
    case .refreshRulesClicked,
         .administrateClicked,
         .viewNetworkTrafficClicked,
         .turnOnFilterClicked,
         .suspendFilterClicked:
      state.dropdownOpen = false
      return .none

    case .connectFailedHelpClicked:
      return .exec { _ in
        await device.openWebUrl(URL(string: "https://gertrude.app/contact")!)
      }

    default:
      return .none
    }
  }
}

extension MenuBarFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .menuBar(.quitForNowClicked):
      return adminAuthenticated(action)

    case .adminAuthed(.menuBar(.quitForNowClicked)):
      return .exec { _ in
        await self.api.securityEvent(.appQuit)
        await self.app.quit()
      }

    case .menuBar(.removeFilterClicked):
      return adminAuthenticated(action)

    case .adminAuthed(.menuBar(.removeFilterClicked)):
      return .exec { _ in
        await self.api.securityEvent(.systemExtensionChangeRequested, "uninstall")
        _ = await self.filter.uninstall()
      }

    case .menuBar(.quitForUninstallClicked):
      return adminAuthenticated(action)

    case .adminAuthed(.menuBar(.quitForUninstallClicked)):
      return .exec { _ in
        await self.api.securityEvent(.appQuit, "for uninstall")
        _ = await self.xpc.disconnectUser()
        _ = await self.filter.uninstall()
        await self.storage.deleteAll()
        try? await self.mainQueue.sleep(for: .milliseconds(100))
        await self.app.quit()
      }

    case .menuBar(.pauseDowntimeClicked):
      return adminAuthenticated(action)

    case .adminAuthed(.menuBar(.pauseDowntimeClicked(duration: let duration))):
      guard let downtime = state.user.data?.downtime,
            downtime.contains(self.now, in: self.calendar) else {
        return .none
      }
      let expiration = duration.expiration(from: self.now)
      state.user.downtimePausedUntil = expiration
      return .exec { _ in
        _ = await self.xpc.pauseDowntime(expiration)
      }

    case .menuBar(.resumeDowntimeClicked):
      state.user.downtimePausedUntil = nil
      return .exec { _ in
        _ = await self.xpc.endDowntimePause()
      }

    default:
      return .none
    }
  }
}

extension MenuBarFeature.Reducer {
  typealias State = MenuBarFeature.State
  typealias Action = MenuBarFeature.Action
}

extension MenuBarFeature.Action.DowntimePauseDuration {
  func expiration(from date: Date) -> Date {
    switch self {
    case .tenMinutes:
      date + .minutes(10)
    case .oneHour:
      date + .hours(1)
    case .oneDay:
      date + .days(1)
    }
  }
}
