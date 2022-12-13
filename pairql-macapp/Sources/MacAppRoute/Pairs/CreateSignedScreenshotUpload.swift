import Foundation
import PairQL

public struct CreateSignedScreenshotUpload: Pair {
  public static let auth: ClientAuth = .user

  public struct Input: PairInput {
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
