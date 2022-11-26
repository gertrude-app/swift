public extension Int {
  static var random: Int {
    Int.random(in: 1000000000 ... 9999999999)
  }
}

public extension Int64 {
  static var random: Int64 {
    Int64.random(in: 1000000000 ... 9999999999)
  }
}

public extension String {
  var random: String {
    "\(self) \(Int.random)"
  }
}
