import Runtime

public struct EnumType: Equatable {
  struct Case: Equatable {
    struct Value: Equatable {
      let name: String
      let type: String
    }

    let name: String
    let values: [Value]
    let isFlattenedUserStruct: Bool

    init(name: String, values: [Value], isFlattenedUserStruct: Bool = false) {
      self.name = name
      self.values = values
      self.isFlattenedUserStruct = isFlattenedUserStruct
    }
  }

  let name: String
  let cases: [Case]
}

// helpers

func fullyQualifiedTypeName(_ type: Any.Type) -> String {
  String(reflecting: type)
    .split(separator: ".")
    .dropFirst() // drop the module name
    .joined(separator: ".")
}

// extensions

public extension EnumType {
  init(from type: Any.Type) throws {
    let info = try typeInfo(of: type)
    guard info.kind == .enum else {
      throw TypeScriptError(message: "Expected enum type, got \(info.kind)")
    }

    self.init(
      name: fullyQualifiedTypeName(info.type),
      cases: try info.cases.map { try .init(from: $0) }
    )
  }

  internal var helperStructs: String {
    let structs = cases.compactMap(\.codableStruct)
    if structs.isEmpty {
      return ""
    } else {
      return structs.joined(separator: "\n\n  ") + "\n\n  "
    }
  }

  var codableConformance: String {
    """
    extension \(name) {
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

      \(helperStructs)public func encode(to encoder: Encoder) throws {
        switch self {
        \(cases.map(\.encodeCase).joined(separator: "\n    "))
        }
      }

      public init(from decoder: Decoder) throws {
        let caseName = try _NamedCase.extract(from: decoder)
        let container = try decoder.singleValueContainer()
        switch caseName {
        \(cases.map(\.initCase).joined(separator: "\n    "))
        default:
          throw _TypeScriptDecodeError(message: "Unexpected case name: `\\(caseName)`")
        }
      }
    }
    """
  }

  var unimplementedConformance: String {
    """
    extension \(name) {
      public func encode(to encoder: Encoder) throws {
        fatalError("Not implemented")
      }

      public init(from decoder: Decoder) throws {
        fatalError("Not implemented")
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
    if case .tuple = payloadType.kind {
      self = .init(
        name: caseData.name,
        values: try payloadType.properties.map { try .init(from: $0) }
      )
      // flatten unary payload of a user struct: `case foo(SomeStruct)`
    } else if payloadType.isUserStruct {
      self = .init(
        name: caseData.name,
        values: try payloadType.properties.map { try .init(from: $0) },
        isFlattenedUserStruct: true
      )
    } else {
      self = .init(name: caseData.name, values: [
        .init(name: caseData.name, type: payloadType.name),
      ])
    }
  }

  var codableStructName: String {
    "_Case\(name.capitalized)"
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
    } else if isFlattenedUserStruct {
      return "case .\(name)(let unflat):"
    } else {
      return "case .\(name)(let \(values.map(\.name).joined(separator: ", let "))):"
    }
  }

  var encodeInit: String {
    if values.isEmpty {
      return "_NamedCase(case: \"\(name)\")"
    } else {
      var args = values.map(\.name).map { "\($0): \($0)" }
      if isFlattenedUserStruct {
        args = values.map(\.name).map { "\($0): unflat.\($0)" }
      }
      return "\(codableStructName)(\(args.joined(separator: ", ")))"
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
      var args = values.map { $0.constructArg(caseName: name) }
        .joined(separator: ", ")
      if isFlattenedUserStruct {
        args = ".init(\(args))"
      }
      return #"""
      case "\#(name)":
            let value = try container.decode(\#(codableStructName).self)
            self = .\#(name)(\#(args))
      """#
    }
  }
}

extension EnumType.Case.Value {
  init(from property: PropertyInfo) throws {
    let typeInfo = try typeInfo(of: property.type)
    if typeInfo.isOptional {
      let inner = typeInfo.genericTypes[0]
      self.init(name: property.name, type: "\(fullyQualifiedTypeName(inner))?")
    } else {
      self.init(name: property.name, type: "\(fullyQualifiedTypeName(property.type))")
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
