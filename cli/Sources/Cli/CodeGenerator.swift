protocol CodeGenerator {
  func write() throws
  func format() throws
}

extension CodeGenerator {
  func format() throws {}
}

protocol AggregateCodeGenerator: CodeGenerator {
  var generators: [CodeGenerator] { get }
}

extension AggregateCodeGenerator {
  func write() throws {
    try generators.write()
    try format()
  }
}

extension Sequence where Element == CodeGenerator {
  func write() throws {
    for element in self {
      try element.write()
      try element.format()
    }
  }
}
