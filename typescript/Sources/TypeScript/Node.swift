import Runtime

indirect enum Node: Equatable {
  case primitive(Primitive)
  case array(Node)
  case object([Property])
  case union([Node])

  enum Primitive: Equatable {
    case string
    case stringLiteral(String)
    case number
    case boolean
    case null
    case void
    case never
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
    case is Void.Type:
      self = .primitive(.void)
    case is Never.Type:
      self = .primitive(.never)
    default:
      try self.init(from: typeInfo(of: type))
    }
  }

  init(caseWithValue case: Case) throws {
    let caseProp = Node.Property(
      name: "case",
      value: .primitive(.stringLiteral(`case`.name))
    )

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
      for member in associatedValueType.properties {
        guard member.name != "" else {
          throw Node.Error(message: "Multiple unnamed tuple members are not supported")
        }
        properties.append(.init(
          name: member.name,
          value: try Node(from: member.type),
          optional: try member.isOptional
        ))
      }
      self = .object(properties)

      // flatten unary struct associated value: Foo.bar(SomeStruct)
    } else if associatedValueType.kind == .struct,
              case .object(let structProps) = try Node(from: associatedValueType.type) {
      properties.append(contentsOf: structProps)
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
      throw Error(message: "Tuples are not supported")
    default:
      throw Error(message: "Unexpected type: \(type.name), kind: \(type.kind)")
    }
  }
}

extension Node {
  struct Error: Swift.Error {
    let message: String
  }
}
