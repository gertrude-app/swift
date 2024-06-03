struct Context {
  let config: Config
  let depth: Int

  init(config: Config = .init(), depth: Int = 0) {
    self.config = config
    self.depth = depth
  }

  var inline: Context {
    Context(config: self.config, depth: self.depth)
  }

  var indent: String {
    self.config.compact ? " " : String(repeating: " ", count: self.depth * 2)
  }

  var newLine: String {
    self.config.compact ? "" : "\n"
  }

  var indentedNewLine: String {
    self.config.compact ? "" : "\n\(self.indent)"
  }

  func compact(_ compact: String, or expanded: String) -> String {
    self.config.compact ? compact : expanded
  }
}

postfix operator ++

extension Context {
  static postfix func ++ (lhs: Context) -> Context {
    Context(config: lhs.config, depth: lhs.depth + 1)
  }
}
