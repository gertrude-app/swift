import PairQL

public enum IOSRoute: PairRoute {
  case blockRules(BlockRules.Input)
  case logIOSEvent(LogIOSEvent.Input)
}

public extension IOSRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, IOSRoute> = OneOf {
    Route(.case(Self.blockRules)) {
      Operation(BlockRules.self)
      Body(.json(BlockRules.Input.self))
    }
    Route(.case(Self.logIOSEvent)) {
      Operation(LogIOSEvent.self)
      Body(.json(LogIOSEvent.Input.self))
    }
  }
  .eraseToAnyParserPrinter()
}
