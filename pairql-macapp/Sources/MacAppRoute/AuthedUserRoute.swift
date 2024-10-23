import Gertie
import PairQL

public enum AuthedUserRoute: PairRoute {
  case checkIn(CheckIn.Input)
  case createKeystrokeLines(CreateKeystrokeLines.Input)
  case createSignedScreenshotUpload(CreateSignedScreenshotUpload.Input)
  case createSuspendFilterRequest(CreateSuspendFilterRequest.Input)
  case createSuspendFilterRequest_v2(CreateSuspendFilterRequest_v2.Input)
  case createUnlockRequests_v2(CreateUnlockRequests_v2.Input)
  case createUnlockRequests_v3(CreateUnlockRequests_v3.Input)
  case getAccountStatus
  case getUserData
  case logFilterEvents(LogFilterEvents.Input)
  case logSecurityEvent(LogSecurityEvent.Input)
  case refreshRules(RefreshRules.Input)
  case reportBrowsers(ReportBrowsers.Input)
}

public extension AuthedUserRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, AuthedUserRoute> = OneOf {
    Route(.case(Self.checkIn)) {
      Operation(CheckIn.self)
      Body(.json(CheckIn.Input.self))
    }
    Route(.case(Self.createKeystrokeLines)) {
      Operation(CreateKeystrokeLines.self)
      Body(.json(CreateKeystrokeLines.Input.self))
    }
    Route(.case(Self.createSignedScreenshotUpload)) {
      Operation(CreateSignedScreenshotUpload.self)
      Body(.json(CreateSignedScreenshotUpload.Input.self))
    }
    Route(.case(Self.createSuspendFilterRequest)) {
      Operation(CreateSuspendFilterRequest.self)
      Body(.json(CreateSuspendFilterRequest.Input.self))
    }
    Route(.case(Self.createSuspendFilterRequest_v2)) {
      Operation(CreateSuspendFilterRequest_v2.self)
      Body(.json(CreateSuspendFilterRequest_v2.Input.self))
    }
    Route(.case(Self.createUnlockRequests_v2)) {
      Operation(CreateUnlockRequests_v2.self)
      Body(.json(CreateUnlockRequests_v2.Input.self))
    }
    Route(.case(Self.createUnlockRequests_v3)) {
      Operation(CreateUnlockRequests_v3.self)
      Body(.json(CreateUnlockRequests_v3.Input.self))
    }
    Route(.case(Self.getAccountStatus)) {
      Operation(GetAccountStatus.self)
    }
    Route(.case(Self.getUserData)) {
      Operation(GetUserData.self)
    }
    Route(.case(Self.logFilterEvents)) {
      Operation(LogFilterEvents.self)
      Body(.json(LogFilterEvents.Input.self))
    }
    Route(.case(Self.logSecurityEvent)) {
      Operation(LogSecurityEvent.self)
      Body(.json(LogSecurityEvent.Input.self))
    }
    Route(.case(Self.refreshRules)) {
      Operation(RefreshRules.self)
      Body(.json(RefreshRules.Input.self))
    }
    Route(.case(Self.reportBrowsers)) {
      Operation(ReportBrowsers.self)
      Body(.json(ReportBrowsers.Input.self))
    }
  }
  .eraseToAnyParserPrinter()
}
