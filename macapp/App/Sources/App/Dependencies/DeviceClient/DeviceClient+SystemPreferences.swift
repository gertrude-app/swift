import AppKit

enum SystemPrefsLocation: Equatable {
  enum SecurityLocation: Equatable {
    case accessibility
    case inputMonitoring
    case screenRecording
    case fullDiskAccess
  }

  case security(SecurityLocation)
  case accounts
  case notifications

  static var baseURL: String {
    "x-apple.systempreferences:com.apple.preference"
  }
}

@Sendable func openSystemPrefs(at location: SystemPrefsLocation) async {
  switch location {
  case .security(let securityLocation):
    let base = SystemPrefsLocation.baseURL + ".security?Privacy_"
    switch securityLocation {
    case .fullDiskAccess:
      openWorkspaceUrl(base + "AllFiles")
    case .screenRecording:
      openWorkspaceUrl(base + "ScreenCapture")
    case .inputMonitoring:
      openWorkspaceUrl(base + "ListenEvent")
    case .accessibility:
      openWorkspaceUrl(base + "Accessibility")
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
}

private func openWorkspaceUrl(_ url: String) {
  guard let url = URL(string: url) else { return }
  NSWorkspace.shared.open(url)
}
