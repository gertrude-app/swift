import Foundation
import Runtime

public indirect enum Node: Equatable {
  case primitive(Primitive)
  case array(Node, AnyType)
  case object([Property], AnyType)
  case record(Node)
  case stringUnion([String], AnyType)
  case objectUnion([ObjectUnionMember], AnyType)

  public enum Primitive: Equatable {
    case string
    case stringLiteral(String)
    case number(AnyType)
    case boolean
    case null
    case void
    case date
    case uuid
    case never
  }

  var anyType: AnyType {
    switch self {
    case .array(_, let anyType):
      .array(of: anyType.type)
    case .object(_, let type):
      type
    case .objectUnion(_, let type):
      type
    case .primitive(let primitive):
      primitive.anyType
    case .record(let node):
      node.anyType
    case .stringUnion(_, let type):
      type
    }
  }

  public struct ObjectUnionMember: Equatable {
    var caseName: String
    var associatedValues: [Property]

    init(caseName: String, associatedValues: [Property] = []) {
      self.caseName = caseName
      self.associatedValues = associatedValues
    }
  }

  public struct Property: Equatable {
    var name: String
    var value: Node
    var optional: Bool
    var readonly: Bool

    init(
      name: String,
      value: Node,
      optional: Bool = false,
      readonly: Bool = false
    ) {
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
    case is Int.Type,
         is Int32.Type,
         is Int64.Type,
         is UInt.Type,
         is UInt32.Type,
         is UInt64.Type,
         is Float.Type,
         is Double.Type:
      self = .primitive(.number(.init(type)))
    case is Bool.Type:
      self = .primitive(.boolean)
    case is Void.Type:
      self = .primitive(.void)
    case is Never.Type:
      self = .primitive(.never)
    case is Date.Type:
      self = .primitive(.date)
    case is UUID.Type:
      self = .primitive(.uuid)
    default:
      try self.init(from: typeInfo(of: type))
    }
  }

  init(from type: TypeInfo) throws {
    switch type.kind {
    case .struct where type.isArray:
      self = try .array(Node(from: type.genericTypes[0]), .init(type.genericTypes[0]))
    case .struct where type.isDict && type.genericTypes[0] == String.self:
      self = try .record(Node(from: type.genericTypes[1]))
    case .struct where type.isDict:
      throw Error(message: "Dictionaries with non-string keys are not supported")
    case .struct:
      self = try .object(type.properties.map(Node.Property.init), .init(type.type))
    case .optional:
      self = try Node(from: type.genericTypes[0])
    case .enum where type.numberOfPayloadEnumCases == 0:
      self = .stringUnion(type.cases.map(\.name), .init(type.type))
    case .enum:
      self = try .objectUnion(type.cases.map { try .init(caseWithValue: $0) }, .init(type.type))
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

extension Node.ObjectUnionMember {
  init(caseWithValue case: Case) throws {
    self = .init(caseName: `case`.name, associatedValues: [])
    guard let associatedValue = `case`.payloadType else {
      return
    }

    let associatedValueType = try typeInfo(of: associatedValue)

    // unary named values come through as unary tuple: Foo.bar(foo: Int)
    if associatedValueType.kind == .tuple, associatedValueType.properties.count == 1 {
      let member = associatedValueType.properties[0]
      try associatedValues.append(.init(
        name: member.name,
        value: Node(from: member.type),
        optional: member.isOptional
      ))

      // n-ary tuples: Foo.bar(Int, Int), Foo.bar(foo: Int, bar: Int)
    } else if associatedValueType.kind == .tuple {
      for member in associatedValueType.properties {
        guard member.name != "" else {
          throw Node.Error(message: "Multiple unnamed tuple members are not supported")
        }
        try associatedValues.append(.init(
          name: member.name,
          value: Node(from: member.type),
          optional: member.isOptional
        ))
      }

      // flatten unary struct associated value: Foo.bar(SomeStruct)
    } else if associatedValueType.kind == .struct,
              case .object(let structProps, _) = try Node(from: associatedValueType.type) {
      associatedValues.append(contentsOf: structProps)

      // unary non-tuple associated value: Foo.bar(Int)
    } else {
      try associatedValues.append(.init(
        name: `case`.name,
        value: Node(from: associatedValue),
        optional: associatedValueType.kind == .optional
      ))
    }
  }
}

extension Node.Primitive {
  var anyType: AnyType {
    switch self {
    case .boolean:
      .bool
    case .date:
      .init(Date.self)
    case .never:
      .init(fullyQualifiedName: "Swift.Never", name: "Never", type: Never.self)
    case .null:
      .init(fullyQualifiedName: "TypeScriptInterop.Null", name: "Null", type: Any?.self)
    case .number(let type):
      type
    case .string:
      .init(String.self)
    case .stringLiteral:
      .init(String.self)
    case .uuid:
      .init(UUID.self)
    case .void:
      .init(Void.self)
    }
  }
}
