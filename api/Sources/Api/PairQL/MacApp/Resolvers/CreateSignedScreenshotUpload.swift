import Dependencies
import MacAppRoute
import Vapor

#if os(Linux)
  @preconcurrency import Foundation
#else
  import Foundation
#endif

extension CreateSignedScreenshotUpload: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    let computerUser = try await context.computerUser()
    let unixTime = Int(Date().timeIntervalSince1970)
    let filename = "\(unixTime)--\(context.uuid().lowercased).jpg"
    let filepath = "\(computerUser.id.lowercased)/\(filename)"
    let dir = "\(context.env.mode == .prod ? "" : "\(context.env.mode)-")screenshots"
    let objectName = "\(dir)/\(filepath)"
    let webUrlString = "\(context.env.s3.bucketUrl)/\(objectName)"

    guard let webUrl = URL(string: webUrlString) else {
      throw Abort(
        .internalServerError,
        reason: "Unexpected nil constructing signed upload url"
      )
    }

    let signedUrl = try with(dependency: \.aws).signedS3UploadUrl(objectName)

    try await context.db.create(Screenshot(
      computerUserId: computerUser.id,
      url: webUrlString,
      width: input.width,
      height: input.height,
      filterSuspended: input.filterSuspended ?? false,
      createdAt: input.createdAt ?? get(dependency: \.date.now)
    ))

    return .init(uploadUrl: signedUrl, webUrl: webUrl)
  }
}
