import PairQL

public enum AuthedRoute: PairRoute {
  case blockRules_v3(BlockRules_v3.Input)
  case createSuspendFilterRequest(CreateSuspendFilterRequest.Input)
  case pollFilterSuspensionDecision(PollFilterSuspensionDecision.Input)
  case screenshotUploadUrl(ScreenshotUploadUrl.Input)
}

public extension AuthedRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, AuthedRoute> = OneOf {
    Route(.case(Self.blockRules_v3)) {
      Operation(BlockRules_v3.self)
      Body(.json(BlockRules_v3.Input.self))
    }
    Route(.case(Self.createSuspendFilterRequest)) {
      Operation(CreateSuspendFilterRequest.self)
      Body(.json(CreateSuspendFilterRequest.Input.self))
    }
    Route(.case(Self.pollFilterSuspensionDecision)) {
      Operation(PollFilterSuspensionDecision.self)
      Body(.json(PollFilterSuspensionDecision.Input.self))
    }
    Route(.case(Self.screenshotUploadUrl)) {
      Operation(ScreenshotUploadUrl.self)
      Body(.json(ScreenshotUploadUrl.Input.self))
    }
  }
  .eraseToAnyParserPrinter()
}
