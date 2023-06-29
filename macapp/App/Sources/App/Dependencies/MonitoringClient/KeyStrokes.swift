import Cocoa
import Foundation

// NB: this whole file is legacy, but has been working fine, and i sort of
// hacked it in to the new app... at some point, should rewrite

struct Keystroke {
  typealias Modifiers = NSEvent.ModifierFlags

  static let NEWLINE_KEYCODE: UInt16 = 36
  static let BACKSPACE_KEYCODE: UInt16 = 51
  static let ESCAPE_KEYCODE: UInt16 = 53

  var char: Character
  var keyCode: UInt16
  var modifiers: Modifiers
  var timestamp: TimeInterval
  var date = Date()

  var isNewline: Bool {
    switch (char, keyCode) {
    case ("\r", _), (_, Self.NEWLINE_KEYCODE):
      return true
    default:
      return false
    }
  }

  var isBackspace: Bool {
    keyCode == Self.BACKSPACE_KEYCODE
  }

  var isEscape: Bool {
    keyCode == Self.ESCAPE_KEYCODE
  }

  var display: String {
    if modifiers.contains(.control) {
      return " <CTRL-\(char)> "
    } else if modifiers.contains(.option) {
      return " <OPT-\(char)> "
    } else if modifiers.contains(.command) {
      return " <⌘\(char)> "
    } else if isEscape {
      return "<ESC>"
    } else if char.isWhitespace || !char.isASCII {
      return " "
    } else {
      return String(char)
    }
  }

  init(
    char: Character,
    keyCode: UInt16 = 0,
    modifiers: Modifiers = [],
    timestamp: TimeInterval = 0
  ) {
    self.char = char
    self.keyCode = keyCode
    self.modifiers = modifiers
    self.timestamp = timestamp
  }

  init?(from event: NSEvent) {
    guard let str = event.characters, str.unicodeScalars.count == 1 else {
      return nil
    }
    char = Character(str)
    keyCode = event.keyCode
    modifiers = event.modifierFlags
    timestamp = event.timestamp
  }
}

class Keystrokes {
  private static let SAMELINE_DELTA = 3.75
  private static let BACKSPACE_DELTA = 0.75
  private var lastEvent: TimeInterval = 0
  private var currentLineKey: TimeInterval?
  private(set) var lines: [TimeInterval: String] = [:]
  private(set) var lineDates: [TimeInterval: Date] = [:]

  func receive(_ keystroke: Keystroke) {
    let char = keystroke.char
    var lineKey = keystroke.timestamp
    if let current = currentLineKey, lineKey - lastEvent < Self.SAMELINE_DELTA {
      lineKey = current
    }

    lastEvent = keystroke.timestamp

    if keystroke.isNewline {
      currentLineKey = nil
      return
    }

    guard lines[lineKey] == nil else {
      addKeystroke(keystroke, lineKey)
      return
    }

    if char.isWhitespace {
      return
    }

    lineDates[keystroke.timestamp] = keystroke.date
    currentLineKey = keystroke.timestamp
    lines[keystroke.timestamp] = ""
    addKeystroke(keystroke, keystroke.timestamp)
  }

  private func addKeystroke(_ keystroke: Keystroke, _ key: TimeInterval) {
    guard let line = lines[key] else {
      return
    }

    if keystroke.isBackspace, keystroke.timestamp - lastEvent < Self.BACKSPACE_DELTA {
      lines[key] = String(line.dropLast())
      return
    }

    let display = keystroke.display
    if display == " ", line.hasSuffix(" ") {
      return
    }

    lines[key] = line + display
  }
}

// extensions

extension Keystroke: CustomStringConvertible {
  var description: String {
    "\(char.isASCII ? String(char) : "<non-ascii>") keyCode=\(keyCode), mods=\(modifiers), time=\(timestamp), isWhitespace=\(char.isWhitespace) debug=\(char.debugDescription)"
  }
}

extension Keystrokes: CustomStringConvertible {
  var description: String {
    Array(lines.keys).sorted().map { timestamp in
      var dateStr = ""
      if let date = lineDates[timestamp] {
        dateStr = String(describing: date)
      } else {
        dateStr = String(describing: Date(timeIntervalSince1970: 0))
      }
      return "\(dateStr): \(lines[timestamp] ?? "")"
    }.joined(separator: "\n")
  }
}
