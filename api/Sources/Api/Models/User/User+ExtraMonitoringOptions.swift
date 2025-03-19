import Gertie

extension FilterSuspensionDecision.ExtraMonitoring {
  var magicString: String {
    switch self {
    case .addKeylogging:
      "k"
    case .setScreenshotFreq(let frequency):
      "@\(frequency)"
    case .addKeyloggingAndSetScreenshotFreq(let frequency):
      "@\(frequency)+k"
    }
  }

  init?(magicString: String) {
    var input = magicString
    if input == "k" {
      self = .addKeylogging
    } else if input.hasPrefix("@") {
      input.removeFirst()
      var withKeylogging = false
      if input.hasSuffix("+k") {
        withKeylogging = true
        input.removeLast(2)
      }
      guard let frequency = Int(input) else {
        return nil
      }
      if withKeylogging {
        self = .addKeyloggingAndSetScreenshotFreq(frequency)
      } else {
        self = .setScreenshotFreq(frequency)
      }
    } else {
      return nil
    }
  }
}

extension User {
  var extraMonitoringOptions: [FilterSuspensionDecision.ExtraMonitoring: String] {
    var opts: [FilterSuspensionDecision.ExtraMonitoring: String] = [:]
    if !keyloggingEnabled {
      opts[.addKeylogging] = "keylogging"
    }

    if !screenshotsEnabled {
      opts[.setScreenshotFreq(120)] = "Screenshot every 2m"
      opts[.setScreenshotFreq(90)] = "Screenshot every 90s"
      opts[.setScreenshotFreq(60)] = "Screenshot every 60s"
      opts[.setScreenshotFreq(30)] = "Screenshot every 30s"

      if !keyloggingEnabled {
        opts[.addKeyloggingAndSetScreenshotFreq(120)] = "Screenshot every 2m + keylogging"
        opts[.addKeyloggingAndSetScreenshotFreq(90)] = "Screenshot every 90s + keylogging"
        opts[.addKeyloggingAndSetScreenshotFreq(60)] = "Screenshot every 60s + keylogging"
        opts[.addKeyloggingAndSetScreenshotFreq(30)] = "Screenshot every 30s + keylogging"
      }
    } else {
      opts[.setScreenshotFreq(Int(Double(screenshotsFrequency) / 1.5))] = "1.5x screenshots"
      opts[.setScreenshotFreq(screenshotsFrequency / 2)] = "2x screenshots"
      opts[.setScreenshotFreq(screenshotsFrequency / 3)] = "3x screenshots"

      if !keyloggingEnabled {
        opts[.addKeyloggingAndSetScreenshotFreq(Int(Double(screenshotsFrequency) / 1.5))] =
          "1.5x screenshots + keylogging"
        opts[.addKeyloggingAndSetScreenshotFreq(screenshotsFrequency / 2)] =
          "2x screenshots + keylogging"
        opts[.addKeyloggingAndSetScreenshotFreq(screenshotsFrequency / 3)] =
          "3x screenshots + keylogging"
      }
    }

    opts = opts.filter { opt, _ in
      opt.screenshotsFrequency ?? Int.max > 10
    }

    return opts
  }
}
