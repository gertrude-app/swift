import Foundation
import PairQL

/// in use: v2.0.0 - present
public struct CreateSignedScreenshotUpload: Pair {
  public static let auth: ClientAuth = .user

  public struct Input: PairInput {
    public let width: Int
    public let height: Int
    public let createdAt: Date?

    public init(width: Int, height: Int, createdAt: Date? = nil) {
      self.width = width
      self.height = height
      self.createdAt = createdAt
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
