import PairQL

#if os(Linux)
  @preconcurrency import Foundation
#else
  import Foundation
#endif

/// in use: v1.5.0 - present
public struct ScreenshotUploadUrl: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public let width: Int
    public let height: Int
    public let createdAt: Date

    public init(width: Int, height: Int, createdAt: Date) {
      self.width = width
      self.height = height
      self.createdAt = createdAt
    }
  }

  public struct Output: PairOutput {
    public let uploadUrl: URL

    public init(uploadUrl: URL) {
      self.uploadUrl = uploadUrl
    }
  }
}
