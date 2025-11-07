import Runtime

extension TypeInfo {
  var isUserStruct: Bool {
    guard kind == .struct else { return false }
    // ignore structs like String, Bool, Date, Int, etc...
    return properties.map(\.name).count(where: { !$0.starts(with: "_") }) > 0
  }

  var isArray: Bool {
    kind == .struct && name.starts(with: "Array<") && genericTypes.count == 1
  }

  var isDict: Bool {
    kind == .struct && name.starts(with: "Dictionary<") && genericTypes.count == 2
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
