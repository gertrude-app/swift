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

@Sendable func commitKestrokes(filterSuspended: Bool) async {
  monitor.withValue {
    $0.commitPendingKeystrokes(filterSuspended: filterSuspended)
  }
}

@Sendable func takeKeystrokes() async -> CreateKeystrokeLines.Input? {
  monitor.withValue {
    let keystrokes = $0.takeKeystrokes()
    return keystrokes.isEmpty ? nil : keystrokes
  }
}

@Sendable func restoreKeystrokes(_ keystrokes: CreateKeystrokeLines.Input) async {
  monitor.withValue { $0.appendBufferedApiInput(keystrokes) }
}

private let monitor = Mutex(KeystrokeMonitor())

class KeystrokeMonitor {
  private var eventMonitor: Any?
  private var appKeystrokes: [String: Keystrokes] = [:]
  private var bufferedApiInput: CreateKeystrokeLines.Input = []

  func start() {
    stop() // if we don't stop prior, we get duplicate keystrokes
    eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { event in
      guard let keystroke = Keystroke(from: event),
            let appName = NSWorkspace.shared.frontmostApplication?.localizedName else {
        return
      }
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

  func appendBufferedApiInput(_ input: CreateKeystrokeLines.Input) {
    bufferedApiInput.append(contentsOf: input)
    if bufferedApiInput.count > 2000 {
      @Dependency(\.date.now) var now
      let sevenDaysAgo = Date(subtractingDays: 7, from: now)
      bufferedApiInput = bufferedApiInput.filter { $0.time > sevenDaysAgo }
    }
  }

  func commitPendingKeystrokes(filterSuspended: Bool) {
    let keystrokes = appKeystrokes
    appKeystrokes = [:]
    appendBufferedApiInput(keystrokes.flatMap { appName, keystrokes in
      keystrokes.lines.compactMap { timestamp, line in
        guard let date = keystrokes.lineDates[timestamp] else {
          return nil
        }
        if line.trimmingCharacters(in: .whitespaces).isEmpty {
          return nil
        }
        return .init(appName: appName, line: line, filterSuspended: filterSuspended, time: date)
      }
    })
  }

  func takeKeystrokes() -> CreateKeystrokeLines.Input {
    defer { bufferedApiInput = [] }
    return bufferedApiInput
  }

  func stop() {
    if let eventMonitor {
      NSEvent.removeMonitor(eventMonitor)
      self.eventMonitor = nil
    }
  }
}
