import Runtime

public enum EnumCodableGen {}

public extension EnumCodableGen {
  struct EnumType: Equatable {
    struct Case: Equatable {
      struct Value: Equatable {
        enum Name: Equatable {
          case none(caseName: String)
          case some(String)
        }

        let name: Name
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
}

// helpers

func typeName(_ type: Any.Type) -> String {
  String(reflecting: type)
    .split(separator: ".")
    .dropFirst() // drop the module name
    .joined(separator: ".")
}

// extensions

public extension EnumCodableGen.EnumType {
  init(from type: Any.Type) throws {
    let info = try typeInfo(of: type)
    guard info.kind == .enum else {
      throw NonEnumError(message: "Expected enum type, got \(info.kind)")
    }

    self.init(
      name: typeName(info.type),
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

  func codableConformance(public: Bool = false) -> String {
    """
    \(`public` ? "public " : "")extension \(name) {
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

      \(helperStructs)func encode(to encoder: Encoder) throws {
        switch self {
        \(cases.map(\.encodeCase).joined(separator: "\n    "))
        }
      }

      init(from decoder: Decoder) throws {
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

  func unimplementedConformance(public: Bool = false) -> String {
    """
    \(`public` ? "public " : "")extension \(name) {
      func encode(to encoder: Encoder) throws {
        fatalError("Not implemented")
      }

      init(from decoder: Decoder) throws {
        fatalError("Not implemented")
      }
    }
    """
  }
}

extension EnumCodableGen.EnumType.Case {
  init(from caseData: Case) throws {
    guard let payload = caseData.payloadType else {
      self = .init(name: caseData.name, values: [])
      return
    }
    let payloadType = try typeInfo(of: payload)

    // tuple payloads, eg: .foo(a: Int, b: Bool), .bar(c: String), .baz(Int, Bool)
    // but NOT .foo(Int), which falls into `else` branch below
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
      // mostly (i think) single, unnamed payloads, like `case foo(Int)`
    } else {
      self = .init(name: caseData.name, values: [
        .init(name: .none(caseName: caseData.name), type: payloadType.name),
      ])
    }
  }

  var codableStructName: String {
    "_Case\(name.prefix(1).capitalized + name.dropFirst())"
  }

  var codableStruct: String? {
    guard !values.isEmpty else { return nil }
    return """
    private struct \(codableStructName): Codable {
        var `case` = "\(name)"
        \(values.map { "var \($0.requireName): \($0.type)" }.joined(separator: "\n    "))
      }
    """
  }

  var switchPattern: String {
    if values.isEmpty {
      return "case .\(name):"
    } else if isFlattenedUserStruct {
      return "case .\(name)(let unflat):"
    } else {
      return "case .\(name)(let \(values.map(\.requireName).joined(separator: ", let "))):"
    }
  }

  var encodeInit: String {
    if values.isEmpty {
      return "_NamedCase(case: \"\(name)\")"
    } else {
      var args = values.map(\.requireName).map { "\($0): \($0)" }
      if isFlattenedUserStruct {
        args = values.map(\.requireName).map { "\($0): unflat.\($0)" }
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
      var args = values.map(\.constructArg).joined(separator: ", ")
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

extension EnumCodableGen.EnumType.Case.Value {
  init(from property: PropertyInfo) throws {
    let typeInfo = try typeInfo(of: property.type)
    if typeInfo.isOptional {
      let inner = typeInfo.genericTypes[0]
      self.init(name: .some(property.name), type: "\(typeName(inner))?")
    } else {
      self.init(name: .some(property.name), type: "\(typeName(property.type))")
    }
  }

  var constructArg: String {
    switch name {
    case .some(let name):
      return "\(name): value.\(name)"
    case .none(let caseName):
      return "value.\(caseName)"
    }
  }

  var requireName: String {
    switch name {
    case .none(let caseName):
      return caseName
    case .some(let label):
      return label
    }
  }
}

struct NonEnumError: Error {
  var message: String
}
