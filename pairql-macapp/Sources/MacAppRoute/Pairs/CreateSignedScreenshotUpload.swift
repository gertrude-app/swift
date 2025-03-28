import PairQL

#if os(Linux)
  @preconcurrency import Foundation
#else
  import Foundation
#endif

/// in use: v2.0.0 - present
public struct CreateSignedScreenshotUpload: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public let width: Int
    public let height: Int
    public var filterSuspended: Bool?
    public let createdAt: Date?

    public init(
      width: Int,
      height: Int,
      filterSuspended: Bool? = false,
      createdAt: Date? = nil
    ) {
      self.width = width
      self.height = height
      self.filterSuspended = filterSuspended
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
