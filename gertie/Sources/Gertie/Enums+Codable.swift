// auto-generated, do not edit
import Foundation

public extension FilterSuspensionDecision {
  private struct _NamedCase: Codable {
    var `case`: String
    static func extract(from decoder: Decoder) throws -> String {
      let container = try decoder.singleValueContainer()
      return try container.decode(_NamedCase.self).case
    }
  }

  private struct _TypeScriptDecodeError: Error {
    var message: String
  }

  private struct _CaseAccepted: Codable {
    var `case` = "accepted"
    var durationInSeconds: Int
    var doubledScreenshots: FilterSuspensionDecision.DoubledScreenshots?
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .accepted(let durationInSeconds, let doubledScreenshots):
      try _CaseAccepted(
        durationInSeconds: durationInSeconds,
        doubledScreenshots: doubledScreenshots
      ).encode(to: encoder)
    case .rejected:
      try _NamedCase(case: "rejected").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "accepted":
      let value = try container.decode(_CaseAccepted.self)
      self = .accepted(
        durationInSeconds: value.durationInSeconds,
        doubledScreenshots: value.doubledScreenshots
      )
    case "rejected":
      self = .rejected
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}
