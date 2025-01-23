// taken from @link https://github.com/ddddxxx/Semver
import Foundation

public struct Semver {
  /// The major version.
  public let major: Int

  /// The minor version.
  public let minor: Int

  /// The patch version.
  public let patch: Int

  /// The pre-release identifiers (if any).
  public let prerelease: [String]

  /// The build metadatas (if any).
  public let buildMetadata: [String]

  /// Creates a version with the provided values.
  ///
  /// The result is unchecked. Use `isValid` to validate the version.
  public init(
    major: Int,
    minor: Int,
    patch: Int,
    prerelease: [String] = [],
    buildMetadata: [String] = []
  ) {
    self.major = major
    self.minor = minor
    self.patch = patch
    self.prerelease = prerelease
    self.buildMetadata = buildMetadata
  }

  /// A string representation of prerelease identifiers (if any).
  public var prereleaseString: String? {
    self.prerelease.isEmpty ? nil : self.prerelease.joined(separator: ".")
  }

  /// A string representation of build metadatas (if any).
  public var buildMetadataString: String? {
    self.buildMetadata.isEmpty ? nil : self.buildMetadata.joined(separator: ".")
  }

  /// A Boolean value indicating whether the version is pre-release version.
  public var isPrerelease: Bool {
    !self.prerelease.isEmpty
  }

  /// A Boolean value indicating whether the version conforms to Semantic
  /// Versioning 2.0.0.
  ///
  /// An invalid Semver can only be formed with the memberwise initializer
  /// `Semver.init(major:minor:patch:prerelease:buildMetadata:)`.
  public var isValid: Bool {
    self.major >= 0
      && self.minor >= 0
      && self.patch >= 0
      && self.prerelease.allSatisfy(validatePrereleaseIdentifier)
      && self.buildMetadata.allSatisfy(validateBuildMetadataIdentifier)
  }

  public static let zero = Semver(major: 0, minor: 0, patch: 0)
}

public extension Semver {
  init(os: OperatingSystemVersion) {
    self.init(major: os.majorVersion, minor: os.minorVersion, patch: os.patchVersion)
  }

  static func fromOperatingSystemVersion() -> Semver {
    Semver(os: ProcessInfo.processInfo.operatingSystemVersion)
  }
}

extension Semver: Equatable {
  /// Semver semantic equality. Build metadata is ignored.
  public static func == (lhs: Semver, rhs: Semver) -> Bool {
    lhs.major == rhs.major &&
      lhs.minor == rhs.minor &&
      lhs.patch == rhs.patch &&
      lhs.prerelease == rhs.prerelease
  }

  /// Swift semantic equality.
  public static func === (lhs: Semver, rhs: Semver) -> Bool {
    (lhs == rhs) && (lhs.buildMetadata == rhs.buildMetadata)
  }

  /// Swift semantic unequality.
  public static func !== (lhs: Semver, rhs: Semver) -> Bool {
    !(lhs === rhs)
  }
}

extension Semver: Sendable {}
extension Semver: Hashable {}

extension Semver: Comparable {
  public static func < (lhs: Semver, rhs: Semver) -> Bool {
    guard lhs.major == rhs.major else {
      return lhs.major < rhs.major
    }
    guard lhs.minor == rhs.minor else {
      return lhs.minor < rhs.minor
    }
    guard lhs.patch == rhs.patch else {
      return lhs.patch < rhs.patch
    }
    guard lhs.isPrerelease else {
      return false // Non-prerelease lhs >= potentially prerelease rhs
    }
    guard rhs.isPrerelease else {
      return true // Prerelease lhs < non-prerelease rhs
    }
    return lhs.prerelease.lexicographicallyPrecedes(rhs.prerelease) { lpr, rpr in
      if lpr == rpr { return false }
      // FIXME: deal with big integers
      switch (UInt(lpr), UInt(rpr)) {
      case (let l?, let r?): return l < r
      case (nil, nil): return lpr < rpr
      case (_?, nil): return true
      case (nil, _?): return false
      }
    }
  }
}

extension Semver: Codable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let str = try container.decode(String.self)
    guard let version = Semver(str) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid semantic version"
      )
    }
    self = version
  }
}

extension Semver: LosslessStringConvertible {
  private nonisolated(unsafe) static let semverRegexPattern =
    #"^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([\da-zA-Z\-]+(?:\.[\da-zA-Z\-]+)*))?$"#
  private nonisolated(unsafe) static let semverRegex =
    try! NSRegularExpression(pattern: semverRegexPattern)

  public init?(_ description: String) {
    guard let match = Semver.semverRegex.firstMatch(in: description) else {
      return nil
    }
    guard let major = Int(description[match.range(at: 1)]!),
          let minor = Int(description[match.range(at: 2)]!),
          let patch = Int(description[match.range(at: 3)]!) else {
      // version number too large
      return nil
    }
    self.major = major
    self.minor = minor
    self.patch = patch
    self.prerelease = description[match.range(at: 4)]?.components(separatedBy: ".") ?? []
    self.buildMetadata = description[match.range(at: 5)]?.components(separatedBy: ".") ?? []
  }

  public var description: String {
    var result = "\(major).\(minor).\(patch)"
    if !self.prerelease.isEmpty {
      result += "-" + self.prerelease.joined(separator: ".")
    }
    if !self.buildMetadata.isEmpty {
      result += "+" + self.buildMetadata.joined(separator: ".")
    }
    return result
  }

  public var string: String { self.description }
}

extension Semver: ExpressibleByStringLiteral {
  public init(stringLiteral value: StaticString) {
    guard let v = Semver(value.description) else {
      preconditionFailure("failed to initialize `Semver` using string literal '\(value)'.")
    }
    self = v
  }
}

// MARK: Foundation Extensions

public extension Bundle {
  /// Use `CFBundleShortVersionString` key
  var semanticVersion: Semver? {
    (infoDictionary?["CFBundleShortVersionString"] as? String).flatMap(Semver.init(_:))
  }
}

// MARK: - Utilities

private func validatePrereleaseIdentifier(_ str: String) -> Bool {
  guard validateBuildMetadataIdentifier(str) else {
    return false
  }
  let isNumeric = str.unicodeScalars.allSatisfy(CharacterSet.asciiDigits.contains)
  return !(isNumeric && (str.first == "0") && (str.count > 1))
}

private func validateBuildMetadataIdentifier(_ str: String) -> Bool {
  !str.isEmpty && str.unicodeScalars.allSatisfy(CharacterSet.semverIdentifierAllowed.contains)
}

private extension CharacterSet {
  nonisolated(unsafe) static let semverIdentifierAllowed: CharacterSet = {
    var set = CharacterSet(charactersIn: "0" ... "9")
    set.insert(charactersIn: "a" ... "z")
    set.insert(charactersIn: "A" ... "Z")
    set.insert("-")
    return set
  }()

  nonisolated(unsafe) static let asciiDigits = CharacterSet(charactersIn: "0" ... "9")
}

private extension String {
  subscript(nsRange: NSRange) -> String? {
    guard let r = Range(nsRange, in: self) else {
      return nil
    }
    return String(self[r])
  }
}

private extension NSRegularExpression {
  func matches(
    in string: String,
    options: NSRegularExpression.MatchingOptions = []
  ) -> [NSTextCheckingResult] {
    let r = NSRange(string.startIndex ..< string.endIndex, in: string)
    return self.matches(in: string, options: options, range: r)
  }

  func firstMatch(
    in string: String,
    options: NSRegularExpression.MatchingOptions = []
  ) -> NSTextCheckingResult? {
    let r = NSRange(string.startIndex ..< string.endIndex, in: string)
    return self.firstMatch(in: string, options: options, range: r)
  }
}
