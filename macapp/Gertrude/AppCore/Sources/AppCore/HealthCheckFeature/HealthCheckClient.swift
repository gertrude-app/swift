import Combine
import Foundation
import UserNotifications

struct HealthCheckClient {
  var runChecks: () -> AnyPublisher<AppAction, Never>
  var restartFilter: () -> AnyPublisher<AppAction, Never>
  var refreshRules: () -> AnyPublisher<AppAction, Never>
}

extension HealthCheckClient {
  static var live: Self {
    .init(
      runChecks: _runChecks,
      restartFilter: _restartFilter,
      refreshRules: _refreshRules
    )
  }
}

extension HealthCheckClient {
  static var noop: Self {
    .init(
      runChecks: { Empty<AppAction, Never>().eraseToAnyPublisher() },
      restartFilter: { Empty<AppAction, Never>().eraseToAnyPublisher() },
      refreshRules: { Empty<AppAction, Never>().eraseToAnyPublisher() }
    )
  }
}

// implementations

private func _refreshRules() -> AnyPublisher<AppAction, Never> {
  Publishers.Merge3(
    Just(.healthCheck(.reset)), // force spinning state
    Just(.userInitiatedRefreshRules),
    Just(.healthCheck(.runAll)).delay(for: 3.0, scheduler: DispatchQueue.main)
  )
  .eraseToAnyPublisher()
}

private func _restartFilter() -> AnyPublisher<AppAction, Never> {
  Publishers.Merge4(
    Just(.healthCheck(.reset)), // force spinning state
    Just(.emitAppEvent(.stopFilter)),
    Just(.emitAppEvent(.startFilter)).delay(for: 2.0, scheduler: DispatchQueue.main),
    Just(.healthCheck(.runAll)).delay(for: 4.0, scheduler: DispatchQueue.main)
  )
  .eraseToAnyPublisher()
}

private func _runChecks() -> AnyPublisher<AppAction, Never> {
  Publishers.Merge8(
    Just(.emitAppEvent(.requestLatestAppVersion)),

    Publishers.Merge(
      Just(.healthCheck(.setBool(
        \.screenRecordingPermissionGranted,
        ScreenshotsPlugin.permissionGranted
      ))),

      Just(.healthCheck(.setBool(
        \.keystrokeRecordingPermissionGranted,
        KeyloggingPlugin.permissionGranted
      )))
    ),

    Future { promise in
      getCurrentUserType { type in
        promise(.success(.healthCheck(.setMacOsUserType(type))))
      }
    },

    Future { promise in
      SendToFilter.communicationTest { success in
        promise(.success(.healthCheck(.setBool(\.filterCommunicationVerified, success))))
      }
    },

    Future { promise in
      SendToFilter.getVersionString { version in
        promise(.success(.healthCheck(.setString(\.filterVersion, version))))
      }
    },

    Future { promise in
      SendToFilter.getNumKeysLoaded(for: getuid()) { numKeys in
        promise(.success(.healthCheck(.setInt(\.filterKeys, numKeys))))
      }
    },

    Just(.requestCurrentAccountStatus),

    Future { promise in
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        if settings.authorizationStatus != .authorized || settings.alertStyle == .none {
          promise(.success(.healthCheck(.setNotificationsPermission(.none))))
        } else if settings.alertStyle == .banner {
          promise(.success(.healthCheck(.setNotificationsPermission(.banner))))
        } else {
          promise(.success(.healthCheck(.setNotificationsPermission(.alert))))
        }
      }
    }
  )
  .eraseToAnyPublisher()
}

private func getCurrentUserType(
  _ handler: @escaping (AdminWindowState.HealthCheckState.MacOsUserType) -> Void
) {
  DispatchQueue.main.async {
    do {
      let proc = Process()
      let pipe = Pipe()
      proc.executableURL = URL(fileURLWithPath: "/usr/bin/id")
      proc.arguments = ["\(getuid())"]
      proc.standardOutput = pipe
      try proc.run()
      proc.waitUntilExit()

      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      if let string = String(data: data, encoding: String.Encoding.utf8) {
        handler(string.contains("(admin)") ? .admin : .standard)
      } else {
        handler(.errorDetermining)
      }
    } catch {
      handler(.errorDetermining)
    }
  }
}
