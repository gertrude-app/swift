import Runtime

struct EnumType: Equatable {
  struct Case: Equatable {
    struct Value: Equatable {
      let name: String
      let type: String
    }

    let name: String
    let values: [Value]
  }

  let name: String
  let cases: [Case]
}

// extensions

extension EnumType {
  init(from type: Any.Type) throws {
    let info = try typeInfo(of: type)
    guard info.kind == .enum else {
      throw TypeScriptError(message: "Expected enum type, got \(info.kind)")
    }

    self.init(name: info.name, cases: try info.cases.map { try .init(from: $0) })
  }

  var helperStructs: String {
    let structs = cases.compactMap(\.codableStruct)
    if structs.isEmpty {
      return ""
    } else {
      return structs.joined(separator: "\n\n  ") + "\n\n  "
    }
  }

  var codableConformance: String {
    """
    extension \(name): Codable {
      \(helperStructs)func encode(to encoder: Encoder) throws {
        switch self {
        \(cases.map(\.encodeCase).joined(separator: "\n    "))
        }
      }

      init(from decoder: Decoder) throws {
        let caseName = try NamedCase.name(from: decoder)
        let container = try decoder.singleValueContainer()
        switch caseName {
        \(cases.map(\.initCase).joined(separator: "\n    "))
        default:
          throw TypeScriptError(message: "Unexpected case name: `\\(caseName)`")
        }
      }
    }
    """
  }
}

extension EnumType.Case {
  init(from caseData: Case) throws {
    guard let payload = caseData.payloadType else {
      self = .init(name: caseData.name, values: [])
      return
    }
    let payloadType = try typeInfo(of: payload)
    switch payloadType.kind {
    case .tuple:
      self = .init(
        name: caseData.name,
        values: try payloadType.properties.map { try .init(from: $0) }
      )
    default:
      self = .init(name: caseData.name, values: [
        .init(name: caseData.name, type: payloadType.name),
      ])
      return
    }
  }

  var codableStructName: String {
    "Case\(name.capitalized)"
  }

  var codableStruct: String? {
    guard !values.isEmpty else { return nil }
    return """
    private struct \(codableStructName): Codable {
        var `case` = "\(name)"
        \(values.map { "var \($0.name): \($0.type)" }.joined(separator: "\n    "))
      }
    """
  }

  var switchPattern: String {
    if values.isEmpty {
      return "case .\(name):"
    } else {
      return "case .\(name)(let \(values.map(\.name).joined(separator: ", let "))):"
    }
  }

  var encodeInit: String {
    if values.isEmpty {
      return "NamedCase(\"\(name)\")"
    } else {
      let args = values.map(\.name).map { "\($0): \($0)" }
      return "Case\(name.capitalized)(\(args.joined(separator: ", ")))"
    }
  }

  var encodeCase: String {
    "\(switchPattern)\n      try \(encodeInit).encode(to: encoder)"
  }

  var initCase: String {
    if values.isEmpty {
      return #"""
      case "\#(name)":
            self = .\#(name)
      """#
    } else {
      let args = values.map { $0.constructArg(caseName: name) }
      return #"""
      case "\#(name)":
            let value = try container.decode(\#(codableStructName).self)
            self = .\#(name)(\#(args.joined(separator: ", ")))
      """#
    }
  }
}

extension EnumType.Case.Value {
  init(from property: PropertyInfo) throws {
    let typeInfo = try typeInfo(of: property.type)
    if typeInfo.isOptional {
      let inner = typeInfo.genericTypes[0]
      self.init(name: property.name, type: "\(inner)?")
    } else {
      self.init(name: property.name, type: "\(property.type)")
    }
  }

  func constructArg(caseName: String) -> String {
    if caseName == name {
      return "value.\(name)"
    } else {
      return "\(name): value.\(name)"
    }
  }
}

struct TypeScriptError: Error {
  var message: String
}

public struct NamedCase: Codable {
  public var `case`: String

  public init(_ case: String) {
    self.case = `case`
  }

  public static func name(from decoder: Decoder) throws -> String {
    let container = try decoder.singleValueContainer()
    return try container.decode(NamedCase.self).case
  }
}
