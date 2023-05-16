import Cocoa
import Combine
import Core
import Dependencies
import MacAppRoute

@Sendable func startKeylogging() async {
  monitor.withValue { $0.start() }
}

@Sendable func stopKeylogging() async {
  monitor.withValue { $0.stop() }
}

@Sendable func takeKeystrokes() async -> CreateKeystrokeLines.Input? {
  monitor.withValue {
    let keystrokes = $0.takeKeystrokes()
    return keystrokes.isEmpty ? nil : keystrokes
  }
}

private let monitor = Mutex(KeystrokeMonitor())

class KeystrokeMonitor {
  private var eventMonitor: Any?
  private var appKeystrokes: [String: Keystrokes] = [:]

  func start() {
    eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { event in
      guard let keystroke = Keystroke(from: event),
            let appName = NSWorkspace.shared.frontmostApplication?.localizedName else {
        return
      }
      print(Thread.current, "keystroke: \(keystroke) from \(appName)")
      self.receive(keystroke: keystroke, from: appName)
    }
  }

  func receive(keystroke: Keystroke, from app: String) {
    guard let keystrokes = appKeystrokes[app] else {
      let keystrokes = Keystrokes()
      keystrokes.receive(keystroke)
      appKeystrokes[app] = keystrokes
      return
    }
    keystrokes.receive(keystroke)
  }

  func takeKeystrokes() -> CreateKeystrokeLines.Input {
    let keystrokes = appKeystrokes
    appKeystrokes = [:]
    return keystrokes.flatMap { appName, keystrokes in
      keystrokes.lines.compactMap { timestamp, line in
        guard let date = keystrokes.lineDates[timestamp] else {
          return nil
        }
        if line.trimmingCharacters(in: .whitespaces).isEmpty {
          return nil
        }
        return .init(appName: appName, line: line, time: date)
      }
    }
  }

  func stop() {
    if let eventMonitor {
      NSEvent.removeMonitor(eventMonitor)
    }
  }
}
