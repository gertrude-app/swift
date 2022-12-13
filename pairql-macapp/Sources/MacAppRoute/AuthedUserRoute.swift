import PairQL
import Shared

public enum AuthedUserRoute: PairRoute {
  case getAccountStatus
  case createSignedScreenshotUpload(CreateSignedScreenshotUpload.Input)
}

public extension AuthedUserRoute {
  static let router = OneOf {
    Route(/Self.getAccountStatus) {
      Operation(GetAccountStatus.self)
    }
    Route(/Self.createSignedScreenshotUpload) {
      Operation(CreateSignedScreenshotUpload.self)
      Body(.json(CreateSignedScreenshotUpload.Input.self))
    }
  }
}
