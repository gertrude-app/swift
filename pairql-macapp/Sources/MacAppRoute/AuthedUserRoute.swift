import Gertie
import PairQL

public enum AuthedUserRoute: PairRoute {
  case checkIn(CheckIn.Input)
  case createKeystrokeLines(CreateKeystrokeLines.Input)
  case createSignedScreenshotUpload(CreateSignedScreenshotUpload.Input)
  case createSuspendFilterRequest(CreateSuspendFilterRequest.Input)
  case createUnlockRequests_v2(CreateUnlockRequests_v2.Input)
  case getAccountStatus
  case getUserData
  case logSecurityEvent(LogSecurityEvent.Input)
  case refreshRules(RefreshRules.Input)
  case reportBrowsers(ReportBrowsers.Input)
}

public extension AuthedUserRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, AuthedUserRoute> = OneOf {
    Route(/Self.checkIn) {
      Operation(CheckIn.self)
      Body(.json(CheckIn.Input.self))
    }
    Route(/Self.createKeystrokeLines) {
      Operation(CreateKeystrokeLines.self)
      Body(.json(CreateKeystrokeLines.Input.self))
    }
    Route(/Self.createSignedScreenshotUpload) {
      Operation(CreateSignedScreenshotUpload.self)
      Body(.json(CreateSignedScreenshotUpload.Input.self))
    }
    Route(/Self.createSuspendFilterRequest) {
      Operation(CreateSuspendFilterRequest.self)
      Body(.json(CreateSuspendFilterRequest.Input.self))
    }
    Route(/Self.createUnlockRequests_v2) {
      Operation(CreateUnlockRequests_v2.self)
      Body(.json(CreateUnlockRequests_v2.Input.self))
    }
    Route(/Self.getAccountStatus) {
      Operation(GetAccountStatus.self)
    }
    Route(/Self.getUserData) {
      Operation(GetUserData.self)
    }
    Route(/Self.logSecurityEvent) {
      Operation(LogSecurityEvent.self)
      Body(.json(LogSecurityEvent.Input.self))
    }
    Route(/Self.refreshRules) {
      Operation(RefreshRules.self)
      Body(.json(RefreshRules.Input.self))
    }
    Route(/Self.reportBrowsers) {
      Operation(ReportBrowsers.self)
      Body(.json(ReportBrowsers.Input.self))
    }
  }
  .eraseToAnyParserPrinter()
}
