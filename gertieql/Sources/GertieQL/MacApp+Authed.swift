import Foundation
import Shared
import URLRouting

public extension MacApp {
  enum UserAuthed: Equatable {
    case getUsersAdminAccountStatus
    case createSignedScreenshotUpload(input: CreateSignedScreenshotUpload.Input)
  }
}

public extension MacApp.UserAuthed {
  static let router = OneOf {
    Route(.case(Self.getUsersAdminAccountStatus)) {
      Path { "getUsersAdminAccountStatus" }
    }
    Route(.case(Self.createSignedScreenshotUpload)) {
      Path { "createSignedScreenshotUpload" }
      Body(.json(CreateSignedScreenshotUpload.Input.self))
    }
  }
}

public extension MacApp.UserAuthed {
  struct GetUsersAdminAccountStatus: Pair {
    public struct Output: PairOutput {
      public let status: AdminAccountStatus

      public init(status: AdminAccountStatus) {
        self.status = status
      }
    }
  }

  struct CreateSignedScreenshotUpload: Pair {
    public struct Input: Codable, Equatable {
      public let width: Int
      public let height: Int

      public init(width: Int, height: Int) {
        self.width = width
        self.height = height
      }
    }

    public struct Output: PairOutput {
      public let uploadUrl: URL
      public let webUrl: URL

      public init(uploadUrl: URL, webUrl: URL) {
        self.uploadUrl = uploadUrl
        self.webUrl = webUrl
      }
    }
  }
}
