// auto-generated, do not edit
import Foundation

public extension BlockRule {
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

  private struct _CaseBundleIdContains: Codable {
    var `case` = "bundleIdContains"
    var value: String
  }

  private struct _CaseUrlContains: Codable {
    var `case` = "urlContains"
    var value: String
  }

  private struct _CaseHostnameContains: Codable {
    var `case` = "hostnameContains"
    var value: String
  }

  private struct _CaseHostnameEquals: Codable {
    var `case` = "hostnameEquals"
    var value: String
  }

  private struct _CaseHostnameEndsWith: Codable {
    var `case` = "hostnameEndsWith"
    var value: String
  }

  private struct _CaseTargetContains: Codable {
    var `case` = "targetContains"
    var value: String
  }

  private struct _CaseFlowTypeIs: Codable {
    var `case` = "flowTypeIs"
    var value: FlowType
  }

  private struct _CaseBoth: Codable {
    var `case` = "both"
    var a: BlockRule
    var b: BlockRule
  }

  private struct _CaseUnless: Codable {
    var `case` = "unless"
    var rule: BlockRule
    var negatedBy: [GertieIOS.BlockRule]
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .bundleIdContains(let value):
      try _CaseBundleIdContains(value: value).encode(to: encoder)
    case .urlContains(let value):
      try _CaseUrlContains(value: value).encode(to: encoder)
    case .hostnameContains(let value):
      try _CaseHostnameContains(value: value).encode(to: encoder)
    case .hostnameEquals(let value):
      try _CaseHostnameEquals(value: value).encode(to: encoder)
    case .hostnameEndsWith(let value):
      try _CaseHostnameEndsWith(value: value).encode(to: encoder)
    case .targetContains(let value):
      try _CaseTargetContains(value: value).encode(to: encoder)
    case .flowTypeIs(let value):
      try _CaseFlowTypeIs(value: value).encode(to: encoder)
    case .both(let a, let b):
      try _CaseBoth(a: a, b: b).encode(to: encoder)
    case .unless(let rule, let negatedBy):
      try _CaseUnless(rule: rule, negatedBy: negatedBy).encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "bundleIdContains":
      let value = try container.decode(_CaseBundleIdContains.self)
      self = .bundleIdContains(value: value.value)
    case "urlContains":
      let value = try container.decode(_CaseUrlContains.self)
      self = .urlContains(value: value.value)
    case "hostnameContains":
      let value = try container.decode(_CaseHostnameContains.self)
      self = .hostnameContains(value: value.value)
    case "hostnameEquals":
      let value = try container.decode(_CaseHostnameEquals.self)
      self = .hostnameEquals(value: value.value)
    case "hostnameEndsWith":
      let value = try container.decode(_CaseHostnameEndsWith.self)
      self = .hostnameEndsWith(value: value.value)
    case "targetContains":
      let value = try container.decode(_CaseTargetContains.self)
      self = .targetContains(value: value.value)
    case "flowTypeIs":
      let value = try container.decode(_CaseFlowTypeIs.self)
      self = .flowTypeIs(value: value.value)
    case "both":
      let value = try container.decode(_CaseBoth.self)
      self = .both(a: value.a, b: value.b)
    case "unless":
      let value = try container.decode(_CaseUnless.self)
      self = .unless(rule: value.rule, negatedBy: value.negatedBy)
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}
