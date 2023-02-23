import Runtime

indirect enum Node: Equatable {
  case primitive(Primitive)
  case array(Node)
  case object([Property])
  case union([Node])
  case tuple([TupleMember])

  enum Primitive: Equatable {
    case string
    case stringLiteral(String)
    case number
    case boolean
    case null
  }

  struct TupleMember: Equatable {
    let name: String?
    let value: Node
    let optional: Bool

    init(name: String? = nil, value: Node, optional: Bool = false) {
      self.name = name
      self.value = value
      self.optional = optional
    }
  }

  struct Property: Equatable {
    let name: String
    let value: Node
    let optional: Bool
    let readonly: Bool

    init(name: String, value: Node, optional: Bool = false, readonly: Bool = false) {
      self.name = name
      self.value = value
      self.optional = optional
      self.readonly = readonly
    }
  }
}

extension Node.Property {
  init(from property: PropertyInfo) throws {
    name = property.name
    optional = try typeInfo(of: property.type).kind == .optional
    readonly = !property.isVar
    value = try Node(from: property.type)
  }
}

extension Node {
  init(from type: Any.Type) throws {
    switch type {
    case is String.Type:
      self = .primitive(.string)
    case is Int.Type:
      self = .primitive(.number)
    case is Bool.Type:
      self = .primitive(.boolean)
    default:
      try self.init(from: typeInfo(of: type))
    }
  }

  init(caseWithValue case: Case) throws {
    let caseProp = Node.Property(name: "case", value: .primitive(.stringLiteral(`case`.name)))
    guard let associatedValue = `case`.payloadType else {
      self = .object([caseProp])
      return
    }

    let associatedValueType = try typeInfo(of: associatedValue)
    var properties = [caseProp]

    // unary named values come through as unary tuple: Foo.bar(foo: Int)
    if associatedValueType.kind == .tuple, associatedValueType.properties.count == 1 {
      let member = associatedValueType.properties[0]
      properties.append(.init(
        name: member.name,
        value: try Node(from: member.type),
        optional: try member.isOptional
      ))
      self = .object(properties)

      // n-ary tuples: Foo.bar(Int, Int), Foo.bar(foo: Int, bar: Int)
    } else if associatedValueType.kind == .tuple {
      properties.append(.init(
        name: `case`.name,
        value: .tuple(
          try associatedValueType.properties.map { TupleMember(
            name: $0.name == "" ? nil : $0.name,
            value: try Node(from: $0.type),
            optional: try $0.isOptional
          ) }
        )
      ))
      self = .object(properties)

      // unary non-tuple associated value: Foo.bar(Int)
    } else {
      properties.append(.init(
        name: `case`.name,
        value: try Node(from: associatedValue),
        optional: associatedValueType.kind == .optional
      ))
      self = .object(properties)
    }
  }

  init(from type: TypeInfo) throws {
    switch type.kind {
    case .struct where type.isArray:
      self = .array(try Node(from: type.genericTypes[0]))
    case .struct:
      self = .object(try type.properties.map(Node.Property.init))
    case .optional:
      self = try Node(from: type.genericTypes[0])
    case .enum where type.numberOfPayloadEnumCases == 0:
      self = .union(type.cases.map { .primitive(.stringLiteral($0.name)) })
    case .enum:
      self = .union(try type.cases.map { try Node(caseWithValue: $0) })
    case .tuple:
      self = .tuple(
        try type.properties.map { TupleMember(
          name: $0.name == "" ? nil : $0.name,
          value: try Node(from: $0.type),
          optional: try $0.isOptional
        ) }
      )
    default:
      self = .primitive(.null)
    }
  }
}

extension TypeInfo {
  var isArray: Bool {
    kind == .struct && name.starts(with: "Array<") && genericTypes.count == 1
  }

  var isOptional: Bool {
    kind == .optional
  }
}

extension PropertyInfo {
  var isOptional: Bool {
    get throws {
      try typeInfo(of: type).kind == .optional
    }
  }
}
