@testable import AppCore
import XCTest

class KeystrokeTests: XCTestCase {
  func testReceiveSingleKeystroke() throws {
    let ks = Keystrokes()
    ks.receive("s")
    XCTAssertEqual([0: "s"], ks.lines)
  }

  func testReceiveRapidKeyStrokesCoalescesInSameLine() throws {
    let ks = Keystrokes()
    ks.receive(c("f", delay: 0))
    ks.receive(c("o", delay: 0.01))
    ks.receive(c("o", delay: 0.02))
    XCTAssertEqual([0: "foo"], ks.lines)
  }

  func testLongDelayCreatesNewLine() throws {
    let ks = Keystrokes()
    ks.receive(c("f", delay: 0))
    ks.receive(c("o", delay: 0.01))
    ks.receive(c("o", delay: 0.02))
    ks.receive(c("b", delay: 5))
    ks.receive(c("a", delay: 5.01))
    ks.receive(c("r", delay: 5.02))
    XCTAssertEqual([0: "foo", 5: "bar"], ks.lines)
  }

  func testMultipleSpacesCoalesced() throws {
    let ks = Keystrokes()
    ks.receive(c("f", delay: 0))
    ks.receive(c(" ", delay: 0.01))
    ks.receive(c(" ", delay: 0.02))
    ks.receive(c(" ", delay: 0.03))
    ks.receive(c("o", delay: 0.04))
    XCTAssertEqual([0: "f o"], ks.lines)
  }

  func testTabsRenderedAsSpace() throws {
    let ks = Keystrokes()
    ks.receive(c("a", delay: 0))
    ks.receive(c("\t", delay: 0.01))
    ks.receive(c("b", delay: 0.02))
    XCTAssertEqual([0: "a b"], ks.lines)
  }

  func testMultipleWhitespacesCoalesced() throws {
    let ks = Keystrokes()
    ks.receive(c("f", delay: 0))
    ks.receive(c("\t", delay: 0.01))
    ks.receive(c(" ", delay: 0.02))
    ks.receive(c("\t", delay: 0.03))
    ks.receive(c("o", delay: 0.04))
    XCTAssertEqual([0: "f o"], ks.lines)
  }

  func testDoesntStartANewLineWithWhitespace() throws {
    let ks = Keystrokes()
    ks.receive(c(" ", delay: 0))
    ks.receive(c("h", delay: 0.01))
    ks.receive(c("i", delay: 0.02))
    XCTAssertEqual([0.01: "hi"], ks.lines)
  }

  func testNewlineStartsNewLine() throws {
    let ks = Keystrokes()
    ks.receive(c("h", delay: 3))
    ks.receive(c("i", delay: 3.01))
    ks.receive(c("\r", delay: 3.02, keyCode: 36))
    ks.receive(c("!", delay: 3.03))
    XCTAssertEqual([3: "hi", 3.03: "!"], ks.lines)
  }

  func testMultipleNewlinesCoalesced() throws {
    let ks = Keystrokes()
    ks.receive(c("h", delay: 3))
    ks.receive(c("i", delay: 3.01))
    ks.receive(c("\r", delay: 3.02, keyCode: Keystroke.NEWLINE_KEYCODE))
    ks.receive(c("\r", delay: 3.03, keyCode: Keystroke.NEWLINE_KEYCODE))
    ks.receive(c("\r", delay: 3.04, keyCode: Keystroke.NEWLINE_KEYCODE))
    ks.receive(c("!", delay: 3.05))
    XCTAssertEqual([3: "hi", 3.05: "!"], ks.lines)
  }

  func testRapidBackspaceDeletesLastChar() throws {
    let ks = Keystrokes()
    ks.receive(c("h", delay: 0))
    ks.receive(c("x", delay: 0.01))
    ks.receive(c("•", delay: 0.02, keyCode: Keystroke.BACKSPACE_KEYCODE))
    ks.receive(c("i", delay: 0.03))
    XCTAssertEqual([0: "hi"], ks.lines)
  }

  func testEscapeEncodedSpecial() throws {
    let ks = Keystrokes()
    ks.receive(c("h", delay: 0))
    ks.receive(c("i", delay: 0.01))
    ks.receive(c("•", delay: 0.02, keyCode: Keystroke.ESCAPE_KEYCODE))
    XCTAssertEqual([0: "hi<ESC>"], ks.lines)
  }

  func testModifierKeysTreatedSpecial() throws {
    let ks = Keystrokes()
    ks.receive(Keystroke(char: "t", keyCode: 23, modifiers: [.command], timestamp: 0.02))
    ks.receive(c("h", delay: 0.03))
    ks.receive(c("i", delay: 0.04))
    XCTAssertEqual([0.02: " <⌘t> hi"], ks.lines)
  }

  func testNonAsciiCharsCoalescedIntoSingleSpace() throws {
    let ks = Keystrokes()
    ks.receive(c("h", delay: 0))
    ks.receive(c("*", delay: 0.01))
    ks.receive(c("•", delay: 0.02))
    ks.receive(c("∫", delay: 0.03))
    ks.receive(c("•", delay: 0.035))
    ks.receive(c("i", delay: 0.04))
    XCTAssertEqual([0: "h* i"], ks.lines)
  }

  func testSymbolsDisplayCorrectly() throws {
    let ks = Keystrokes()
    ks.receive(c("!", delay: 0.00))
    ks.receive(c("@", delay: 0.01))
    ks.receive(c("#", delay: 0.02))
    ks.receive(c("$", delay: 0.03))
    ks.receive(c("%", delay: 0.04))
    ks.receive(c("^", delay: 0.04))
    ks.receive(c("&", delay: 0.04))
    ks.receive(c("*", delay: 0.04))
    ks.receive(c("(", delay: 0.04))
    ks.receive(c(")", delay: 0.04))
    ks.receive(c("-", delay: 0.04))
    ks.receive(c("_", delay: 0.04))
    ks.receive(c("+", delay: 0.04))
    ks.receive(c("=", delay: 0.04))
    ks.receive(c("{", delay: 0.04))
    ks.receive(c("}", delay: 0.04))
    ks.receive(c("[", delay: 0.04))
    ks.receive(c("]", delay: 0.04))
    ks.receive(c("|", delay: 0.04))
    XCTAssertEqual([0: "!@#$%^&*()-_+={}[]|"], ks.lines)
  }

  func testPunctuationDisplaysCorrectly() throws {
    let ks = Keystrokes()
    ks.receive(c(".", delay: 0.00))
    ks.receive(c(";", delay: 0.01))
    ks.receive(c(",", delay: 0.02))
    ks.receive(c("?", delay: 0.03))
    ks.receive(c(":", delay: 0.04))
    ks.receive(c("'", delay: 0.04))
    ks.receive(c("\"", delay: 0.04))
    XCTAssertEqual([0: ".;,?:'\""], ks.lines)
  }

  func testGlobalKeystrokes() throws {
    let gks = GlobalKeystrokes()
    gks.receive(keystroke: "h", from: "Brave")
    gks.receive(keystroke: "i", from: "Brave")
    XCTAssertEqual(gks.appKeystrokes["Brave"]?.lines, [0: "hi"])
  }
}

func c(_ ch: Character, delay: TimeInterval = 0, keyCode: UInt16 = 0) -> Keystroke {
  Keystroke(char: ch, keyCode: keyCode, modifiers: [], timestamp: delay)
}

extension Keystroke: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(char: Character(value))
  }
}
