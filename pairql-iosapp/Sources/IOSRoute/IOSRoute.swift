import PairQL

public enum IOSRoute: PairRoute {
  case logIOSEvent(LogIOSEvent.Input)
}

public extension IOSRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, IOSRoute> = OneOf {
    Route(.case(Self.logIOSEvent)) {
      Operation(LogIOSEvent.self)
      Body(.json(LogIOSEvent.Input.self))
    }
  }
  .eraseToAnyParserPrinter()
}
