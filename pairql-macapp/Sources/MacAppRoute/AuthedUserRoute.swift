import PairQL
import Shared

public enum AuthedUserRoute: PairRoute {
  case createSignedScreenshotUpload(CreateSignedScreenshotUpload.Input)
  case getAccountStatus
  case refreshRules
}

public extension AuthedUserRoute {
  static let router = OneOf {
    Route(/Self.createSignedScreenshotUpload) {
      Operation(CreateSignedScreenshotUpload.self)
      Body(.json(CreateSignedScreenshotUpload.Input.self))
    }
    Route(/Self.getAccountStatus) {
      Operation(GetAccountStatus.self)
    }
    Route(/Self.refreshRules) {
      Operation(RefreshRules.self)
    }
  }
}
