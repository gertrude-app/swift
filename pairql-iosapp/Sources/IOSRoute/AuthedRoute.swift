import PairQL

public enum AuthedRoute: PairRoute {
  case connectedRules(ConnectedRules.Input)
  case createSuspendFilterRequest(CreateSuspendFilterRequest.Input)
  case pollFilterSuspensionDecision(PollFilterSuspensionDecision.Input)
  case screenshotUploadUrl(ScreenshotUploadUrl.Input)
}

public extension AuthedRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, AuthedRoute> = OneOf {
    Route(.case(Self.connectedRules)) {
      Operation(ConnectedRules.self)
      Body(.json(ConnectedRules.Input.self))
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
