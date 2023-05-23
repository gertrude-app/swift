import Dependencies
import Foundation
import LaunchAtLogin
import Models

extension AppClient: DependencyKey {
  public static let liveValue = Self(
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
