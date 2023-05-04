import PairQL
import Shared

public enum AuthedUserRoute: PairRoute {
  case createKeystrokeLines(CreateKeystrokeLines.Input)
  case createNetworkDecisions(CreateNetworkDecisions.Input)
  case createSignedScreenshotUpload(CreateSignedScreenshotUpload.Input)
  case createSuspendFilterRequest(CreateSuspendFilterRequest.Input)
  case createUnlockRequests(CreateUnlockRequests.Input)
  case createUnlockRequests_v2(CreateUnlockRequests_v2.Input)
  case getAccountStatus
  case refreshRules(RefreshRules.Input)
}

public extension AuthedUserRoute {
  static let router: AnyParserPrinter<URLRequestData, AuthedUserRoute> = OneOf {
    Route(/Self.createKeystrokeLines) {
      Operation(CreateKeystrokeLines.self)
      Body(.json(CreateKeystrokeLines.Input.self))
    }
    Route(/Self.createNetworkDecisions) {
      Operation(CreateNetworkDecisions.self)
      Body(.json(CreateNetworkDecisions.Input.self))
    }
    Route(/Self.createSignedScreenshotUpload) {
      Operation(CreateSignedScreenshotUpload.self)
      Body(.json(CreateSignedScreenshotUpload.Input.self))
    }
    Route(/Self.createSuspendFilterRequest) {
      Operation(CreateSuspendFilterRequest.self)
      Body(.json(CreateSuspendFilterRequest.Input.self))
    }
    Route(/Self.createUnlockRequests) {
      Operation(CreateUnlockRequests.self)
      Body(.json(CreateUnlockRequests.Input.self))
    }
    Route(/Self.createUnlockRequests_v2) {
      Operation(CreateUnlockRequests_v2.self)
      Body(.json(CreateUnlockRequests_v2.Input.self))
    }
    Route(/Self.getAccountStatus) {
      Operation(GetAccountStatus.self)
    }
    Route(/Self.refreshRules) {
      Operation(RefreshRules.self)
      Body(.json(RefreshRules.Input.self))
    }
  }
  .eraseToAnyParserPrinter()
}
