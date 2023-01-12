import AppKit
import Combine
import Foundation
import SharedCore

enum SystemPrefsLocation: Equatable {
  enum SecurityLocation: Equatable {
    case screenRecording
    case inputMonitoring
  }

  case security(SecurityLocation)
  case accounts
  case notifications

  static var baseURL: String {
    "x-apple.systempreferences:com.apple.preference"
  }
}

enum Os {
  enum Arch: String {
    case arm64
    case x86_64
  }

  struct Version {
    let majorVersion: Int
    let minorVersion: Int
    let patchVersion: Int

    var string: String {
      "\(majorVersion).\(minorVersion).\(patchVersion)"
    }

    var name: String {
      switch majorVersion {
      case 13:
        return "Ventura"
      case 12:
        return "Monterey"
      case 11:
        return "Big Sur"
      default:
        return "__unknown"
      }
    }
  }
}

struct OsClient {
  var arch: () -> Os.Arch?
  var modelIdentifier: () -> String?
  var openSystemPrefs: (SystemPrefsLocation) -> AnyPublisher<Void, Never>
  var openWebUrl: (URL) -> AnyPublisher<Void, Never>
  var quitApp: () -> AnyPublisher<Void, Never>
  var serialNumber: () -> String?
  var version: () -> Os.Version
}

extension OsClient {
  static let live = OsClient(
    arch: {
      var systeminfo = utsname()
      uname(&systeminfo)
      return withUnsafeBytes(of: &systeminfo.machine) {
        String(data: Data($0), encoding: .utf8)
      }
      .map { $0.trimmingCharacters(in: .controlCharacters) }
      .flatMap(Os.Arch.init(rawValue:))
    },

    modelIdentifier: {
      platformData("model", format: .data)?.filter { $0 != Character("\0") }
    },

    openSystemPrefs: { location in
      switch location {
      case .security(let securityLocation):
        let base = SystemPrefsLocation.baseURL + ".security?Privacy_"
        switch securityLocation {
        case .screenRecording:
          openWorkspaceUrl(base + "ScreenCapture")
        case .inputMonitoring:
          openWorkspaceUrl(base + "ListenEvent")
        }
      case .notifications:
        openWorkspaceUrl(SystemPrefsLocation.baseURL + ".notifications")
      case .accounts:
        // apple doesn't seem to allow navigating to accounts pref pane, this _seems_ to work
        Task {
          do {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            proc.arguments = [
              "/System/Library/PreferencePanes/Accounts.prefPane",
            ]
            try proc.run()
            proc.waitUntilExit()
          } catch { /* ¯\_(ツ)_/¯ */ }
        }
      }
      return Empty().eraseToAnyPublisher()

    },
    openWebUrl: { url in
      // @TODO: prevent gertie filter from blocking screenshot test
      NSWorkspace.shared.open(url)
      return Empty().eraseToAnyPublisher()

    },

    quitApp: {
      App.shared.applicationWillTerminate(.init(name: .init(rawValue: "Quit")))
      // give async termination handlers time to clean up
      afterDelayOf(seconds: 2.5) { exit(0) }
      return Empty().eraseToAnyPublisher()
    },

    serialNumber: { platformData(kIOPlatformSerialNumberKey, format: .string) },

    version: {
      var os = ProcessInfo.processInfo.operatingSystemVersion
      return .init(
        majorVersion: os.majorVersion,
        minorVersion: os.minorVersion,
        patchVersion: os.patchVersion
      )
    }
  )
}

extension OsClient {
  static let noop = Self(
    arch: { .arm64 },
    modelIdentifier: { "MacBookNoop99,0" },
    openSystemPrefs: { _ in Empty().eraseToAnyPublisher() },
    openWebUrl: { _ in Empty().eraseToAnyPublisher() },
    quitApp: { Empty().eraseToAnyPublisher() },
    serialNumber: { "NOOPNOOPNOOP" },
    version: { .init(majorVersion: 12, minorVersion: 2, patchVersion: 1) }
  )
}

private func openWorkspaceUrl(_ url: String) {
  guard let url = URL(string: url) else { return }
  NSWorkspace.shared.open(url)
}
