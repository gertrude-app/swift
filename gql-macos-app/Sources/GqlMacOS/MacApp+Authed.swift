import Foundation
import GertieQL
import Shared
import URLRouting

public enum AuthedUserRoute: Equatable {
  case getUsersAdminAccountStatus
  case createSignedScreenshotUpload(CreateSignedScreenshotUpload.Input)
}

public extension AuthedUserRoute {
  static let router = OneOf {
    Route(.case(Self.getUsersAdminAccountStatus)) {
      Path { "getUsersAdminAccountStatus" }
    }
    Route(.case(Self.createSignedScreenshotUpload)) {
      Path { CreateSignedScreenshotUpload.id }
      Body(.json(CreateSignedScreenshotUpload.Input.self))
    }
  }
}

// types

public struct GetUsersAdminAccountStatus: Pair {
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
      return gqlQuery<Input, Output>(input, ClientAuth.\(P.auth) `\(P.id)`)
    }
  }
  """
}

func getTs(_ id: String) -> String? {
  switch id {
  case CreateSignedScreenshotUpload.id:
    return pattern(type: CreateSignedScreenshotUpload.self)
    // return """
    // export namespace CreateSignedScreenshotUpload {
    //   export const slug = `createSignedScreenshotUpload`;

    //   export interface Input {
    //     width: number;
    //     height: number;
    //   }

    //   export interface Output {
    //     uploadUrl: string;
    //     webUrl: string;
    //   }

  //   export async function send(input: Input): Promise<GqlResult<Output>> {
  //     return gqlQuery<Input, Output>(input, slug);
  //   }
  // }
  // """
  default:
    return nil
  }
}

// TODO: this shouldn't be a ts pair, it's for the mac app, duh
public struct CreateSignedScreenshotUpload: TypescriptPair {
  public static let id = "createSignedScreenshotUpload"
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
