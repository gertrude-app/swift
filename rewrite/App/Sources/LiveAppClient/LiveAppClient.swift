import AppKit
import ClientInterfaces
import Combine
import Core
import Dependencies
import Foundation
import LaunchAtLogin

extension AppClient: DependencyKey {
  public static var liveValue: Self {
    initializeColorScheme()
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
      isLaunchAtLoginEnabled: {
        LaunchAtLogin.isEnabled
      },
      installedVersion: {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
      },
      quit: {
        exit(0)
      }
    )
  }
}

// helpers

private let colorSchemeSubject = Mutex(CurrentValueSubject<AppClient.ColorScheme, Never>(.light))
private let retainObserver = Mutex<NSKeyValueObservation?>(nil)

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
