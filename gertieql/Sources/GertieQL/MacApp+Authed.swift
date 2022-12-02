import URLRouting

public extension GertieQL.Route.MacApp {
  enum UserTokenAuthed: Equatable {
    case getUsersAdminAccountStatus
    case createSignedScreenshotUpload(input: LolPair.Input)
  }
}

public extension GertieQL.Route.MacApp.UserTokenAuthed {
  static let router = OneOf {
    Route(.case(Self.getUsersAdminAccountStatus)) {
      Path { "getUsersAdminAccountStatus" }
    }
    Route(.case(Self.createSignedScreenshotUpload)) {
      Path { "createSignedScreenshotUpload" }
      Body(.json(LolPair.Input.self))
    }
  }
}

public struct LolInput: Codable, Equatable {
  let width: Int

  public init(width: Int) {
    self.width = width
  }
}

public protocol Pair: Equatable {
  associatedtype Input: Codable & Equatable
  associatedtype Output: Codable & Equatable
}

// public protocol PairHandler {
//   func handle<P: Pair, Context>(input: P.Input, context: Context) async throws -> P.Output
// }

public struct ZPair<Input: Codable & Equatable, Output: Codable & Equatable, Context> {
  let input: Input
  let resolve: (Input, Context) async throws -> Output
}

public protocol YPair {
  associatedtype Input: Codable & Equatable
  associatedtype Output: Codable & Equatable
  associatedtype Context

  var input: Input { get }
  var resolve: (Input, Context) async throws -> Output { get }
}

public struct Response: Codable, Equatable {
  public let foo: String
}

public struct AnyPair<Context>: YPair {
  public let input: NoInput
  public typealias Input = NoInput
  public typealias Output = Response

  public var resolve: (Input, Context) async throws -> Output

  public init<P: YPair>(pair: P, transform: @escaping (P.Output, P.Context) -> Output)
    where P.Context == Context {
    input = NoInput()
    resolve = { _, context in
      transform(try await pair.resolve(pair.input, context), context)
    }
  }
}

public struct NoInput: Codable, Equatable {}

public struct LolPair: YPair {
  public typealias Context = String
  public var input: Input
  public var resolve: (Input, Context) async throws -> Output

  public struct Input: Codable, Equatable {
    public let width: Int

    public init(width: Int) {
      self.width = width
    }
  }

  public struct Output: Codable, Equatable {
    public let foo: String

    public init(foo: String) {
      self.foo = foo
    }
  }

  public init(
    input: LolPair.Input,
    resolve: @escaping (Input, Context) async throws -> Output
  ) {
    self.input = input
    self.resolve = resolve
  }
}
