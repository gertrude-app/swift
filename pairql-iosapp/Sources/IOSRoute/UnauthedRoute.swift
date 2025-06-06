import PairQL

public enum UnauthedRoute: PairRoute {
  case blockRules(BlockRules.Input)
  case blockRules_v2(BlockRules_v2.Input)
  case connectDevice(ConnectDevice.Input)
  case defaultBlockRules(DefaultBlockRules.Input)
  case logIOSEvent(LogIOSEvent.Input)
  case recoveryDirective(RecoveryDirective.Input)
}

public extension UnauthedRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, UnauthedRoute> = OneOf {
    Route(.case(Self.blockRules)) {
      Operation(BlockRules.self)
      Body(.json(BlockRules.Input.self))
    }
    Route(.case(Self.blockRules_v2)) {
      Operation(BlockRules_v2.self)
      Body(.json(BlockRules_v2.Input.self))
    }
    Route(.case(Self.connectDevice)) {
      Operation(ConnectDevice.self)
      Body(.json(ConnectDevice.Input.self))
    }
    Route(.case(Self.defaultBlockRules)) {
      Operation(DefaultBlockRules.self)
      Body(.json(DefaultBlockRules.Input.self))
    }
    Route(.case(Self.logIOSEvent)) {
      Operation(LogIOSEvent.self)
      Body(.json(LogIOSEvent.Input.self))
    }
    Route(.case(Self.recoveryDirective)) {
      Operation(RecoveryDirective.self)
      Body(.json(RecoveryDirective.Input.self))
    }
  }
  .eraseToAnyParserPrinter()
}
