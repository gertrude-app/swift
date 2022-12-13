import Foundation

@_exported import GertieQL

public enum DashboardRoute: PairRoute {
  case adminAuthed(UUID, AuthedAdminRoute)
  case unauthed(UnAuthedRoute)

  public static let router = OneOf {
    Route(/Self.adminAuthed) {
      Headers { Field("X-UserToken") { UUID.parser() } }
      AuthedAdminRoute.router
    }
    Route(/Self.unauthed) {
      UnAuthedRoute.router
    }
  }
}

public enum UnAuthedRoute: PairRoute {
  case tsCodegen
  public static let router = OneOf {
    Route(/Self.tsCodegen) {
      Operation(TsCodegen.self)
    }
  }
}

public enum AuthedAdminRoute: PairRoute {
  case getUser(GetUser.Input)

  public static let router = OneOf {
    Route(/Self.getUser) {
      Operation(GetUser.self)
      Body(.json(GetUser.Input.self))
    }
  }
}

public struct TsCodegen: Pair, TypescriptPair {
  public static var auth: ClientAuth = .none
  public typealias Output = [String: String]
}

public struct GetUser: Pair, TypescriptPair {
  public static var auth: ClientAuth = .admin
  public typealias Input = UUID

  public struct Output: TypescriptPairOutput {
    public var id: UUID
    public var name: String
    public var keyloggingEnabled: Bool
    public var screenshotsEnabled: Bool
    public var screenshotsResolution: Int
    public var screenshotsFrequency: Int
    public var createdAt: Date

    public init(
      id: UUID,
      name: String,
      keyloggingEnabled: Bool,
      screenshotsEnabled: Bool,
      screenshotsResolution: Int,
      screenshotsFrequency: Int,
      createdAt: Date
    ) {
      self.id = id
      self.name = name
      self.keyloggingEnabled = keyloggingEnabled
      self.screenshotsEnabled = screenshotsEnabled
      self.screenshotsResolution = screenshotsResolution
      self.screenshotsFrequency = screenshotsFrequency
      self.createdAt = createdAt
    }

    public static var ts: String {
      """
      export interface __self__ {
        id: string;
        name: string;
        keyloggingEnabled: boolean;
        screenshotsEnabled: boolean;
        scressnshotResolution: number;
        screenshotsFrequency: number;
        createdAt: string;
      }
      """
    }
  }
}
