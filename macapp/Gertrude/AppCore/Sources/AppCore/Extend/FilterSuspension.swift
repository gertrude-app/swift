import Foundation
import Gertie

public extension FilterSuspension {
  var relativeExpiration: String? {
    Int(expiresAt.timeIntervalSince1970 - Date().timeIntervalSince1970).futureHumanTime
  }
}
