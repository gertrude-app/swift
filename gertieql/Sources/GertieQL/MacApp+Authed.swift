import Foundation
import URLRouting

public extension GertieQL.Route.MacApp {
  enum UserAuthed: Equatable {
    case getUsersAdminAccountStatus
    case createSignedScreenshotUpload(input: CreateSignedScreenshotUpload.Input)
  }
}

public extension GertieQL.Route.MacApp.UserAuthed {
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

public extension GertieQL.Route.MacApp.UserAuthed {
  struct CreateSignedScreenshotUpload: Pair {
    public struct Input: Codable, Equatable {
      public let width: Int
      public let height: Int

      public init(width: Int, height: Int) {
        self.width = width
        self.height = height
      }
    }

    public struct Output: Codable, Equatable {
      public let uploadUrl: URL
      public let webUrl: URL

      public init(uploadUrl: URL, webUrl: URL) {
        self.uploadUrl = uploadUrl
        self.webUrl = webUrl
      }
    }
  }
}

// api
// public protocol PairResolver: Pair {
//   associatedtype Context

//   var input: Input { get }
//   var resolve: (Input, Context) async throws -> Output { get }
// }

// api
// public struct Resolver<P: Pair>: PairResolver {
//   public typealias Input = P.Input
//   public typealias Output = P.Output
//   public typealias Context = String

//   public let input: P.Input
//   public var resolve: (Input, Context) async throws -> Output

//   // public func result(context: Context) async -> GertieQL.Response<Output> {
//   //   do {
//   //     let output = try await resolve(input, context)
//   //     return .success(output)
//   //   } catch {
//   //     // @TODO: handle
//   //     return .error(error.localizedDescription)
//   //   }
//   // }

//   public init(_ input: P.Input, _ resolve: @escaping (P.Input, String) async throws -> P.Output) {
//     self.input = input
//     self.resolve = resolve
//   }
// }
