struct Context {
  let config: Config
  let depth: Int

  init(config: Config = .init(), depth: Int = 0) {
    self.config = config
    self.depth = depth
  }

  var inline: Context {
    Context(config: config, depth: depth)
  }

  var indent: String {
    config.compact ? " " : String(repeating: " ", count: depth * 2)
  }

  var newLine: String {
    config.compact ? "" : "\n"
  }

  var indentedNewLine: String {
    config.compact ? "" : "\n\(indent)"
  }

  func compact(_ compact: String, or expanded: String) -> String {
    config.compact ? compact : expanded
  }
}

postfix operator ++

extension Context {
  static postfix func ++ (lhs: Context) -> Context {
    Context(config: lhs.config, depth: lhs.depth + 1)
  }
}
