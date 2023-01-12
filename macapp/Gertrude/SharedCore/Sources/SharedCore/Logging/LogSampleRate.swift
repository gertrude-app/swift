public extension Log {
  enum SampleRate: Int, Codable {
    case all = 1
    case oneHalf = 2
    case oneThird = 3
    case oneFourth = 4
    case oneFifth = 5
    case oneSixth = 6
    case oneEighth = 8
    case oneTenth = 10
    case oneFiftieth = 50
    case oneHundredth = 100
    case oneThousandth = 1000
    case none = 0

    public func test() -> Bool {
      Double.random(in: 0 ... 100) < percentBetweenZeroandOneHundred
    }

    public var percentBetweenZeroAndOne: Double {
      guard denominatorUnderOne != 0 else { return 0 }
      return percentBetweenZeroandOneHundred / 100.0
    }

    public var percentBetweenZeroandOneHundred: Double {
      guard denominatorUnderOne != 0 else { return 0 }
      return 100.0 / Double(denominatorUnderOne)
    }

    public var denominatorUnderOne: Int {
      rawValue
    }
  }
}
