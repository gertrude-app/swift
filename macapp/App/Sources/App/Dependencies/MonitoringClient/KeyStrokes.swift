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
    switch (self.char, self.keyCode) {
    case ("\r", _), (_, Self.NEWLINE_KEYCODE):
      true
    default:
      false
    }
  }

  var isBackspace: Bool {
    self.keyCode == Self.BACKSPACE_KEYCODE
  }

  var isEscape: Bool {
    self.keyCode == Self.ESCAPE_KEYCODE
  }

  var display: String {
    if self.modifiers.contains(.control) {
      " <CTRL-\(self.char)> "
    } else if self.modifiers.contains(.option) {
      " <OPT-\(self.char)> "
    } else if self.modifiers.contains(.command) {
      " <⌘\(self.char)> "
    } else if self.isEscape {
      "<ESC>"
    } else if self.char.isWhitespace || !self.char.isASCII {
      " "
    } else {
      String(self.char)
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
    self.char = Character(str)
    self.keyCode = event.keyCode
    self.modifiers = event.modifierFlags
    self.timestamp = event.timestamp
  }
}

#if DEBUG
  extension Keystroke: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
      self.init(char: Character(value))
    }
  }
#endif

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

    self.lastEvent = keystroke.timestamp

    if keystroke.isNewline {
      self.currentLineKey = nil
      return
    }

    guard self.lines[lineKey] == nil else {
      self.addKeystroke(keystroke, lineKey)
      return
    }

    if char.isWhitespace {
      return
    }

    self.lineDates[keystroke.timestamp] = keystroke.date
    self.currentLineKey = keystroke.timestamp
    self.lines[keystroke.timestamp] = ""
    self.addKeystroke(keystroke, keystroke.timestamp)
  }

  private func addKeystroke(_ keystroke: Keystroke, _ key: TimeInterval) {
    guard let line = lines[key] else {
      return
    }

    if keystroke.isBackspace, keystroke.timestamp - self.lastEvent < Self.BACKSPACE_DELTA {
      self.lines[key] = String(line.dropLast())
      return
    }

    let display = keystroke.display
    if display == " ", line.hasSuffix(" ") {
      return
    }

    self.lines[key] = line + display
  }
}

// extensions

extension Keystroke: CustomStringConvertible {
  var description: String {
    "\(self.char.isASCII ? String(self.char) : "<non-ascii>") keyCode=\(self.keyCode), mods=\(self.modifiers), time=\(self.timestamp), isWhitespace=\(self.char.isWhitespace) debug=\(self.char.debugDescription)"
  }
}

extension Keystrokes: CustomStringConvertible {
  var description: String {
    Array(self.lines.keys).sorted().map { timestamp in
      var dateStr = ""
      if let date = lineDates[timestamp] {
        dateStr = String(describing: date)
      } else {
        dateStr = String(describing: Date(timeIntervalSince1970: 0))
      }
      return "\(dateStr): \(self.lines[timestamp] ?? "")"
    }.joined(separator: "\n")
  }
}
