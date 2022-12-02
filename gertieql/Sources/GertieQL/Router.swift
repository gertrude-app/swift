import Foundation
import URLRouting

public struct Input: Codable, Equatable {
  public init(width: Int) {
    self.width = width
  }

  public let width: Int
}

public enum GertieQL {
  public enum XRoute: Equatable {
    case dashboard(Dashboard)
    case macApp(MacApp)

    public enum MacApp: Equatable {
      case userTokenAuthed(UUID, UserTokenAuthed)
      case unauthed(UnAuthed)

      public static let router = OneOf {
        Route(.case(MacApp.userTokenAuthed)) {
          Headers { Field("X-UserToken") { UUID.parser() } }
          UserTokenAuthed.router
        }
        Route(.case(MacApp.unauthed)) {
          UnAuthed.router
        }
      }

      public enum UnAuthed: Equatable {
        case register

        public static let router = OneOf {
          Route(.case(UnAuthed.register)) {
            Path { "register" }
          }
        }
      }

      public enum UserTokenAuthed: Equatable {
        case getUsersAdminAccountStatus
        case createSignedScreenshotUpload(input: Input)

        public static let router = OneOf {
          Route(.case(UserTokenAuthed.getUsersAdminAccountStatus)) {
            Path { "getUsersAdminAccountStatus" }
          }
          Route(.case(UserTokenAuthed.createSignedScreenshotUpload)) {
            Path { "createSignedScreenshotUpload" }
            Body(.json(Input.self))
          }
        }
      }
    }

    public enum Dashboard: String, CaseIterable {
      case placeholder
    }
  }

  public static let router = OneOf {
    Route(.case(XRoute.macApp)) {
      Method.post
      Path { "macos-app" }
      XRoute.MacApp.router
    }
    Route(.case(XRoute.dashboard)) {
      Method.post
      Path {
        "dashboard"
        XRoute.Dashboard.parser()
      }
    }
  }
}

let router = Path { "foo" }
