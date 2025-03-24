import AppKit
import ClientInterfaces
import Combine
import Core
import Dependencies
import Foundation
import LaunchAtLogin
import os.log

extension AppClient: @retroactive DependencyKey {
  public static var liveValue: Self {
    initializeColorScheme()
    let stopRelaunchWatcher: @Sendable () -> Void = {
      if let pid = watcherPid.replace(with: nil) {
        os_log("[G•] APP stopping relaunch watcher, pid=%{public}d", pid)
        kill(pid, SIGTERM)
        kill(pid, SIGKILL)
      }
    }
    return AppClient(
      colorScheme: {
        colorSchemeSubject.withValue { $0.value }
      },
      colorSchemeChanges: {
        colorSchemeSubject.withValue { subject in
          Move(subject.eraseToAnyPublisher())
        }.consume()
      },
      disableLaunchAtLogin: {
        LaunchAtLogin.isEnabled = false
      },
      enableLaunchAtLogin: {
        #if !DEBUG
          LaunchAtLogin.isEnabled = true
        #endif
      },
      hasFullDiskAccess: _testFullDiskAccess,
      isLaunchAtLoginEnabled: {
        LaunchAtLogin.isEnabled
      },
      installLocation: {
        Bundle.main.bundleURL
      },
      installedVersion: {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
      },
      preventScreenCaptureNag: _preventScreenCaptureNag,
      quit: {
        stopRelaunchWatcher()
        exit(0)
      },
      relaunch: relaunchApp,
      startRelaunchWatcher: {
        // stopping the debug build in xcode causes the relauncher to restart it
        #if !DEBUG
          if let pid = watcherPid.value {
            os_log("[G•] APP relaunch watcher already running, pid=%{public}d", pid)
          } else {
            let pid = try await startRelauncher()
            watcherPid.replace(with: pid)
            os_log("[G•] APP started relaunch watcher, pid=%{public}d", pid)
          }
        #endif
      },
      stopRelaunchWatcher: { stopRelaunchWatcher() }
    )
  }
}

// helpers

private let colorSchemeSubject = Mutex(CurrentValueSubject<AppClient.ColorScheme, Never>(.light))
private let retainObserver = Mutex<NSKeyValueObservation?>(nil)
private let watcherPid = Mutex<pid_t?>(nil)

private func initializeColorScheme() {
  Task { @MainActor in
    colorSchemeSubject.withValue {
      $0.value = NSApp.effectiveAppearance.name == .darkAqua ? .dark : .light
    }
  }
  Task { @MainActor in
    let observer = NSApp.observe(\.effectiveAppearance) { _, _ in
      Task { @MainActor in
        colorSchemeSubject.withValue {
          $0.value = NSApp.effectiveAppearance.name == .darkAqua ? .dark : .light
        }
      }
    }
    retainObserver.replace(with: observer)
  }
}
