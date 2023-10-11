import Foundation

struct MacOSVersion: Sendable {
  enum Name: String {
    case catalina
    case bigSur
    case monterey
    case ventura
    case sonoma
    case next
  }

  let major: Int
  let minor: Int
  let patch: Int

  var semver: String {
    "\(major).\(minor).\(patch)"
  }

  var name: Name {
    switch (major, minor) {
    case (10, 15): return .catalina
    case (11, _): return .bigSur
    case (12, _): return .monterey
    case (13, _): return .ventura
    case (14, _): return .sonoma
    default: return .next
    }
  }

  var description: String {
    "\(name.rawValue)@\(semver)"
  }
}

@Sendable func macOSVersion() -> MacOSVersion {
  let version = ProcessInfo.processInfo.operatingSystemVersion
  return MacOSVersion(
    major: version.majorVersion,
    minor: version.minorVersion,
    patch: version.patchVersion
  )
}

extension MacOSVersion {
  enum DocumentationGroup: String, Encodable {
    case catalina
    case bigSurOrMonterey
    case venturaOrLater
  }

  var documentationGroup: DocumentationGroup {
    switch name {
    case .catalina:
      return .catalina
    case .bigSur, .monterey:
      return .bigSurOrMonterey
    case .ventura, .sonoma, .next:
      return .venturaOrLater
    }
  }
}

#if DEBUG
  extension MacOSVersion {
    static let sonoma = Self(major: 14, minor: 0, patch: 0)
  }
#endif
