import Foundation
import Gertie

struct MacOSVersion: Sendable {
  enum Name: String, Codable {
    case catalina
    case bigSur
    case monterey
    case ventura
    case sonoma
    case sequoia
    case tahoe
  }

  let major: Int
  let minor: Int
  let patch: Int

  var semver: Semver {
    .init(major: self.major, minor: self.minor, patch: self.patch)
  }

  var name: Name {
    switch (self.major, self.minor) {
    case (10, 15): .catalina
    case (11, _): .bigSur
    case (12, _): .monterey
    case (13, _): .ventura
    case (14, _): .sonoma
    case (15, _): .sequoia
    case (26, _): .sequoia
    default: .tahoe
    }
  }

  var description: String {
    "\(self.name.rawValue)@\(self.semver.string)"
  }
}

@Sendable func macOSVersion() -> MacOSVersion {
  let version = ProcessInfo.processInfo.operatingSystemVersion
  return MacOSVersion(
    major: version.majorVersion,
    minor: version.minorVersion,
    patch: version.patchVersion,
  )
}

#if DEBUG
  extension MacOSVersion {
    static let tahoe = Self(major: 26, minor: 0, patch: 0)
    static let sonoma = Self(major: 14, minor: 0, patch: 0)
    static let sequoia = Self(major: 15, minor: 0, patch: 0)
  }
#endif
