import PairQL

public enum IOSRoute: PairRoute {
  case blockRules(BlockRules.Input)
  case blockRules_v2(BlockRules_v2.Input)
  case defaultBlockRules(DefaultBlockRules.Input)
  case logIOSEvent(LogIOSEvent.Input)
}

public extension IOSRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, IOSRoute> = OneOf {
    Route(.case(Self.blockRules)) {
      Operation(BlockRules.self)
      Body(.json(BlockRules.Input.self))
    }
    Route(.case(Self.blockRules_v2)) {
      Operation(BlockRules_v2.self)
      Body(.json(BlockRules_v2.Input.self))
    }
    Route(.case(Self.defaultBlockRules)) {
      Operation(DefaultBlockRules.self)
      Body(.json(DefaultBlockRules.Input.self))
    }
    Route(.case(Self.logIOSEvent)) {
      Operation(LogIOSEvent.self)
      Body(.json(LogIOSEvent.Input.self))
    }
  }
  .eraseToAnyParserPrinter()
}
