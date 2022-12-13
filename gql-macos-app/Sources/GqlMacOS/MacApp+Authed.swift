import Foundation
import GertieQL
import Shared
import URLRouting

public enum AuthedUserRoute: PairRoute {
  case getUsersAdminAccountStatus
  case createSignedScreenshotUpload(CreateSignedScreenshotUpload.Input)
}

public extension AuthedUserRoute {
  static let router = OneOf {
    Route(/Self.getUsersAdminAccountStatus) {
      Operation(GetUsersAdminAccountStatus.self)
    }
    Route(/Self.createSignedScreenshotUpload) {
      Operation(CreateSignedScreenshotUpload.self)
      Body(.json(CreateSignedScreenshotUpload.Input.self))
    }
  }
}

// types

public struct GetUsersAdminAccountStatus: Pair {
  public static var auth: ClientAuth = .user

  public struct Output: PairOutput {
    public let status: AdminAccountStatus

    public init(status: AdminAccountStatus) {
      self.status = status
    }
  }
}

func pattern<P: TypescriptPair>(type: P.Type) -> String {
  """
  export namespace \(P.self) {
    \(P.Input.ts.replacingOccurrences(of: "__self__", with: "Input"))

    \(P.Output.ts.replacingOccurrences(of: "__self__", with: "Output"))

    export async function send(input: Input): Promise<GqlResult<Output>> {
      return gqlQuery<Input, Output>(input, ClientAuth.\(P.auth), `\(P.name)`)
    }
  }
  """
}

func getTs(_ name: String) -> String? {
  switch name {
  case CreateSignedScreenshotUpload.name:
    return pattern(type: CreateSignedScreenshotUpload.self)
  default:
    return nil
  }
}

// TODO: this shouldn't be a ts pair, it's for the mac app, duh
public struct CreateSignedScreenshotUpload: TypescriptPair {
  public static let auth: ClientAuth = .user

  public struct Input: TypescriptPairInput {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
      self.width = width
      self.height = height
    }

    public static var ts: String {
      """
      interface __self__ {
        width: number;
        height: number;
      }
      """
    }
  }

  public struct Output: TypescriptPairOutput {
    public let uploadUrl: URL
    public let webUrl: URL

    public static var ts: String {
      """
      interface __self__ {
        uploadUrl: string;
        webUrl: string;
      }
      """
    }

    public init(uploadUrl: URL, webUrl: URL) {
      self.uploadUrl = uploadUrl
      self.webUrl = webUrl
    }
  }
}
