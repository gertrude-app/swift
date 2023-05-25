import Gertie
import SwiftUI

struct HealthCheckView: View, StoreView {
  @EnvironmentObject var store: AppStore
  private let rowHeight: CGFloat = 28
  var state: AdminWindowState.HealthCheckState { store.state.adminWindow.healthCheckState }
  var accountStatus: AdminAccountStatus { store.state.accountStatus }

  func icon(_ check: HealthCheck) -> some View {
    Group {
      switch check.state {
      case .checking:
        ProgressView()
          .frame(width: 22, height: 17)
          .scaleEffect(0.5)
          .offset(x: -4, y: 2)
      case .success:
        Label("", systemImage: "checkmark.circle.fill")
          .foregroundColor(green)
      case .warning:
        Label("", systemImage: "minus.circle.fill")
          .foregroundColor(darkMode ? .warningOrange : .orange)
      case .failure:
        Label("", systemImage: "x.circle.fill")
          .foregroundColor(red)
      }
    }
    .frame(width: 25, height: rowHeight)
  }

  var healthChecks: [HealthCheck] {
    [
      HealthCheck(
        title: "App version",
        state: .init(appVersion: Current.appVersion, latestAppVersion: state.latestAppVersion),
        successMeta: "You're on the latest version (\(state.latestAppVersion ?? ""))",
        errorView: {
          AnyView(HStack {
            Text(
              "Click to upgrade from \(Current.appVersion) → \(state.latestAppVersion ?? "")"
            )
            .subtle()
            Button("Upgrade now →") {
              store.send(.emitAppEvent(.requestCheckForUpdates))
            }.buttonStyle(.link)
          })
        }
      ),
      HealthCheck(
        title: "Filter version",
        state: store.state.filterState == .off ? .warning : .init(
          filterVersion: state.filterVersion,
          latestAppVersion: state.latestAppVersion
        ),
        successMeta: "You're on the latest version (\(state.latestAppVersion ?? ""))",
        warnView: "Filter is currently off, can't check version",
        errorView: {
          if let filterVersion = state.filterVersion, filterVersion != Current.appVersion {
            return AnyView(HStack {
              Text("Filter version out of sync, restart filter to fix").subtle()
              Button("Restart") {
                store.send(.healthCheck(.repairFilterCommunication))
              }.buttonStyle(.link)
            })
          }
          return AnyView(Text("Upgrade app by clicking above").subtle())
        }
      ),
      HealthCheck(
        title: "Screen recording permission",
        state: .init(
          permission: state.screenRecordingPermissionGranted,
          enabled: store.state.monitoring.screenshotsEnabled
        ),
        successMeta: "Gertrude has the permissions it needs",
        warnView: "Not required—screenshot feature disabled",
        errorView: {
          AnyView(Button("Grant permissions →") {
            store.send(.openSystemPrefs(.security(.screenRecording)))
          }.buttonStyle(.link))
        }
      ),
      HealthCheck(
        title: "Keystroke recording permission",
        state: .init(
          permission: state.keystrokeRecordingPermissionGranted,
          enabled: store.state.monitoring.screenshotsEnabled
        ),
        successMeta: "Gertrude has the permissions it needs",
        warnView: "Not required—keystroke feature disabled",
        errorView: {
          AnyView(Button("Grant permissions →") {
            store.send(.openSystemPrefs(.security(.inputMonitoring)))
          }.buttonStyle(.link))
        }
      ),
      HealthCheck(
        title: "macOS user account type",
        state: state.macOsUserType == nil ? .checking : state
          .macOsUserType == .admin ? .failure : .success,
        successMeta: "Account type is standard, which is correct",
        errorView: {
          AnyView(Button("Remove user administrator privilege →") {
            store.send(.openSystemPrefs(.accounts))
          }.buttonStyle(.link))
        }
      ),
      HealthCheck(
        title: "Filter to app communication",
        state: store.state
          .filterState == .off ? .warning : .init(state.filterCommunicationVerified),
        successMeta: "Verified",
        warnView: "Filter is currently off, can't check communication",
        errorView: {
          AnyView(HStack(spacing: 5) {
            Text("Broken—can usually be fixed by").subtle()
            Button("restarting the filter →") {
              store.send(.healthCheck(.repairFilterCommunication))
            }.buttonStyle(.link)
          })
        }
      ),
      HealthCheck(
        title: "Notification settings",
        state: .init(state.notificationsPermission),
        successMeta: "Verified",
        warnView: {
          AnyView(HStack(spacing: 5) {
            Text("Set to \"banners\", recommend \"alert\"").subtle()
            Button("fix permission →") {
              store.send(.openSystemPrefs(.notifications))
            }.buttonStyle(.link)
          })
        },
        errorView: {
          AnyView(HStack(spacing: 5) {
            Text("Notifications not allowed").subtle()
            Button("grant permission →") {
              store.send(.openSystemPrefs(.notifications))
            }.buttonStyle(.link)
          })
        }
      ),
      HealthCheck(
        title: "Gertrude account status",
        state: .init(accountStatus: accountStatus),
        successMeta: "Current status: \(accountStatus.userString)",
        warnView: {
          AnyView(HStack(spacing: 4) {
            Text(accountStatus.userString).foregroundColor(.warningOrange).bold()
            Text("Login to the admin dashboard to fix").subtle()
          })
        },
        errorView: {
          AnyView(HStack(spacing: 4) {
            Text(accountStatus.userString).foregroundColor(red).bold()
            Text("Login to the admin dashboard to fix").subtle()
          })
        }
      ),
      HealthCheck(
        title: "Filter rules",
        state: filterRuleState,
        successMeta: "Looks good, \(state.filterKeys ?? 0) keys loaded",
        warnView: store.state.filterState == .off
          ? "Filter is currently off, can't check rules"
          : "No keys loaded, check user in the admin dashboard",
        errorView: {
          AnyView(HStack(spacing: 5) {
            Text("Zero valid keys, try").subtle()
            Button("refreshing rules →") {
              store.send(.healthCheck(.repairFilterRules))
            }.buttonStyle(.link)
          })
        }
      ),
    ]
  }

  var filterRuleState: HealthCheck.State {
    if store.state.filterState == .off {
      return .warning
    }

    guard let numKeys = state.filterKeys else {
      return .checking
    }

    if numKeys == 0 {
      return .warning
    } else if numKeys > 0 {
      return .success
    } else {
      return .failure
    }
  }

  var body: some View {
    let checks = healthChecks
    AdminWindowSubScreen(section: .healthCheck) {
      HStack(spacing: 2) {
        VStack(alignment: .leading, spacing: 0) {
          ForEach(checks) { check in
            icon(check)
          }
        }
        .offset(y: -2)
        VStack(alignment: .leading, spacing: 0) {
          ForEach(checks) { check in
            Text(check.title).frame(height: rowHeight)
          }
        }
        .padding(right: 15)
        VStack(alignment: .leading, spacing: 0) {
          ForEach(checks) { check in
            HStack {
              check.meta
              Spacer()
            }
            .frame(height: rowHeight)
          }
        }
        .frame(maxWidth: .infinity) // hack to help Big Sur :/
        Spacer()
      }
      .padding(left: 15)

      HStack {
        Spacer()
        Button("Recheck...") {
          store.send(.healthCheck(.reset))
          store.send(.healthCheck(.runAll))
        }
        Spacer()
      }
      .padding(top: 15)

      Spacer()
    }
    .onAppear {
      store.send(.healthCheck(.reset))
      store.send(.healthCheck(.runAll))
    }
  }
}

extension Text {
  func subtle() -> some View {
    italic().opacity(0.4)
  }
}

struct HealthCheckView_Previews: PreviewProvider, GertrudeProvider {
  static var cases: [StateCustomizer] = [
    // warning path
    { state in
      state.colorScheme = .light
      state.filterStatus = .installedButNotRunning
      state.accountStatus = .needsAttention
      state.monitoring.keyloggingEnabled = false
      state.monitoring.screenshotsEnabled = false
      state.adminWindow = .healthCheck(.init(
        latestAppVersion: "1.6.0",
        filterVersion: "1.6.0",
        filterCommunicationVerified: nil,
        filterKeys: nil,
        screenRecordingPermissionGranted: false,
        keystrokeRecordingPermissionGranted: false,
        macOsUserType: .admin,
        notificationsPermission: .banner
      ))
    },
    // error path
    { state in
      state.colorScheme = .light
      state.filterStatus = .installedAndRunning
      state.accountStatus = .inactive
      state.monitoring.keyloggingEnabled = true
      state.monitoring.screenshotsEnabled = true
      state.adminWindow = .healthCheck(.init(
        latestAppVersion: "1.7.0",
        filterVersion: "1.6.0",
        filterCommunicationVerified: false,
        filterKeys: 0,
        screenRecordingPermissionGranted: false,
        keystrokeRecordingPermissionGranted: false,
        macOsUserType: .admin,
        notificationsPermission: AdminWindowState.HealthCheckState.NotificationsPermission.none
      ))
    },
    // error path
    { state in
      state.colorScheme = .dark
      state.accountStatus = .inactive
      state.filterStatus = .installedAndRunning
      state.monitoring.keyloggingEnabled = true
      state.monitoring.screenshotsEnabled = true
      state.adminWindow = .healthCheck(.init(
        latestAppVersion: "1.7.0",
        filterVersion: "1.6.0",
        filterCommunicationVerified: false,
        filterKeys: 0,
        screenRecordingPermissionGranted: false,
        keystrokeRecordingPermissionGranted: false,
        macOsUserType: .admin,
        notificationsPermission: AdminWindowState.HealthCheckState.NotificationsPermission.none
      ))
    },
    // happy path
    { state in
      state.colorScheme = .light
      state.filterStatus = .installedAndRunning
      state.accountStatus = .active
      state.monitoring.keyloggingEnabled = true
      state.monitoring.screenshotsEnabled = true
      state.adminWindow = .healthCheck(.init(
        latestAppVersion: "1.6.0",
        filterVersion: "1.6.0",
        filterCommunicationVerified: true,
        filterKeys: 113,
        screenRecordingPermissionGranted: true,
        keystrokeRecordingPermissionGranted: true,
        macOsUserType: .standard,
        notificationsPermission: .alert
      ))
    },
    // happy path
    { state in
      state.colorScheme = .dark
      state.filterStatus = .installedAndRunning
      state.accountStatus = .active
      state.monitoring.keyloggingEnabled = true
      state.monitoring.screenshotsEnabled = true
      state.adminWindow = .healthCheck(.init(
        latestAppVersion: "1.6.0",
        filterVersion: "1.6.0",
        filterCommunicationVerified: true,
        filterKeys: 113,
        screenRecordingPermissionGranted: true,
        keystrokeRecordingPermissionGranted: true,
        macOsUserType: .standard,
        notificationsPermission: .alert
      ))
    },
  ]

  static var previews: some View {
    ForEach(allPreviews) {
      HealthCheckView().store($0).adminPreview()
    }
  }
}
