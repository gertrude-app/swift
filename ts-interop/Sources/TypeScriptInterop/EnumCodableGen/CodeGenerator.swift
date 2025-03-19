public protocol CodeGenerator {
  func write() throws
  func format() throws
}

public extension CodeGenerator {
  func format() throws {}
}

public protocol AggregateCodeGenerator: CodeGenerator {
  var generators: [CodeGenerator] { get }
}

public extension AggregateCodeGenerator {
  func write() throws {
    try generators.write()
    try format()
  }
}

public extension Sequence<CodeGenerator> {
  func write() throws {
    for element in self {
      try element.write()
      try element.format()
    }
  }
}
