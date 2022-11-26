public extension Dictionary {
  func mapKeys<NewKey>(_ f: (Key) -> NewKey) -> [NewKey: Value] {
    var dict: [NewKey: Value] = [:]
    for (key, value) in self {
      dict[f(key)] = value
    }
    return dict
  }
}
