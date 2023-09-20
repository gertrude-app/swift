import Gertie
import XCore
import XCTest
import XExpect

@testable import Api

final class UserExtraMonitoringOptionsTests: ApiTestCase {
  func testExtraMonitoringOptions() {
    let cases: [(Bool, Int?, [FilterSuspensionDecision.ExtraMonitoring: String])] = [
      (
        /* keystrokes already enabled: */ true,
        /* existing screenshots freq:  */ 10, // <-- too fast to increase
        [:]
      ),
      (
        /* keystrokes already enabled: */ false,
        /* existing screenshots freq:  */ 10, // <-- too fast to increase
        [
          .addKeylogging: "keylogging",
        ]
      ),
      (
        /* keystrokes already enabled: */ true,
        /* existing screenshots freq:  */ nil,
        [
          .setScreenshotFreq(120): "Screenshot every 2m",
          .setScreenshotFreq(90): "Screenshot every 90s",
          .setScreenshotFreq(60): "Screenshot every 60s",
          .setScreenshotFreq(30): "Screenshot every 30s",
        ]
      ),
      (
        /* keystrokes already enabled: */ false,
        /* existing screenshots freq:  */ nil,
        [
          .addKeylogging: "keylogging",
          .setScreenshotFreq(120): "Screenshot every 2m",
          .setScreenshotFreq(90): "Screenshot every 90s",
          .setScreenshotFreq(60): "Screenshot every 60s",
          .setScreenshotFreq(30): "Screenshot every 30s",
          .addKeyloggingAndSetScreenshotFreq(120): "Screenshot every 2m + keylogging",
          .addKeyloggingAndSetScreenshotFreq(90): "Screenshot every 90s + keylogging",
          .addKeyloggingAndSetScreenshotFreq(60): "Screenshot every 60s + keylogging",
          .addKeyloggingAndSetScreenshotFreq(30): "Screenshot every 30s + keylogging",
        ]
      ),
      (
        /* keystrokes already enabled: */ true,
        /* existing screenshots freq:  */ 120,
        [
          .setScreenshotFreq(80): "1.5x screenshots",
          .setScreenshotFreq(60): "2x screenshots",
          .setScreenshotFreq(40): "3x screenshots",
        ]
      ),
      (
        /* keystrokes already enabled: */ true,
        /* existing screenshots freq:  */ 30, // <-- 3x would be too fast
        [
          .setScreenshotFreq(20): "1.5x screenshots",
          .setScreenshotFreq(15): "2x screenshots",
        ]
      ),
      (
        /* keystrokes already enabled: */ false,
        /* existing screenshots freq:  */ 120,
        [
          .addKeylogging: "keylogging",
          .setScreenshotFreq(80): "1.5x screenshots",
          .setScreenshotFreq(60): "2x screenshots",
          .setScreenshotFreq(40): "3x screenshots",
          .addKeyloggingAndSetScreenshotFreq(80): "1.5x screenshots + keylogging",
          .addKeyloggingAndSetScreenshotFreq(60): "2x screenshots + keylogging",
          .addKeyloggingAndSetScreenshotFreq(40): "3x screenshots + keylogging",
        ]
      ),
    ]

    for (keylogging, screenshotsFrequency, expected) in cases {
      let user = User.empty {
        $0.keyloggingEnabled = keylogging
        if let screenshotsFrequency {
          $0.screenshotsEnabled = true
          $0.screenshotsFrequency = screenshotsFrequency
        } else {
          $0.screenshotsEnabled = false
        }
      }
      expect(user.extraMonitoringOptions).toEqual(expected)
    }
  }

  func testExtraMonitoringOptionsMagicStringConversions() {
    let cases: [(FilterSuspensionDecision.ExtraMonitoring, String)] = [
      (.addKeylogging, "k"),
      (.setScreenshotFreq(88), "@88"),
      (.addKeyloggingAndSetScreenshotFreq(88), "@88+k"),
    ]
    for (extra, magicString) in cases {
      expect(.init(magicString: magicString)!).toEqual(extra)
      expect(extra.magicString).toEqual(magicString)
    }
  }
}
