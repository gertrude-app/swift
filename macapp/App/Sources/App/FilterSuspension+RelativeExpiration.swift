import Foundation
import Gertie

extension Date {
  func timeRemaining(until future: Date = Date()) -> String {
    let secondsRemaining = Int(future.timeIntervalSince1970 - timeIntervalSince1970)
    switch secondsRemaining {
    case ...0:
      return "now"
    case 1 ..< 45:
      return "less than a minute from now"
    case 45 ..< 85:
      return "about a minute from now"
    case 85 ..< 100:
      return "about 90 seconds from now"
    case 100 ..< 120:
      return "about 2 minutes from now"
    case 120 ..< 3000:
      return "\(Int(round(Double(secondsRemaining) / 60.0))) minutes from now"
    case 3000 ..< 4200:
      return "about an hour from now"
    case 4200 ..< 7200:
      return "1 hour \((secondsRemaining - 3600) / 60) minutes from now"
    case 7200 ..< 172_800:
      return "about \(Int(round(Double(secondsRemaining) / 3600.0))) hours from now"
    default:
      return "\(secondsRemaining / 86400) days from now"
    }
  }

  func shortDuration(until future: Date = Date()) -> String {
    let secondsRemaining = Int(future.timeIntervalSince1970 - timeIntervalSince1970)
    switch secondsRemaining {
    case ...35:
      return "< 1 min"
    case 36 ..< 85:
      return "1 min"
    case 85 ..< 100:
      return "\(secondsRemaining) sec"
    case 100 ..< 120:
      return "2 min"
    case 120 ..< 4200:
      return "\(Int(round(Double(secondsRemaining) / 60.0))) min"
    case 4200 ..< 7200:
      return "1 hr \((secondsRemaining - 3600) / 60) min"
    case 7200 ..< 172_800:
      return "\(Int(round(Double(secondsRemaining) / 3600.0))) hrs"
    default:
      return "\(secondsRemaining / 86400) days"
    }
  }
}

extension FilterSuspension {
  func relativeExpiration(from now: Date = Date()) -> String {
    now.timeRemaining(until: expiresAt)
  }
}
