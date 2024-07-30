import MacAppRoute
import Vapor

#if os(Linux)
  @preconcurrency import Foundation
#else
  import Foundation
#endif

extension CreateSignedScreenshotUpload: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    let userDevice = try await context.userDevice()
    let unixTime = Int(Date().timeIntervalSince1970)
    let filename = "\(unixTime)--\(Current.uuid().lowercased).jpg"
    let filepath = "\(userDevice.id.lowercased)/\(filename)"
    let dir = "\(Env.mode == .prod ? "" : "\(Env.mode)-")screenshots"
    let objectName = "\(dir)/\(filepath)"
    let webUrlString = "\(Env.CLOUD_STORAGE_BUCKET_URL)/\(objectName)"

    guard let webUrl = URL(string: webUrlString) else {
      throw Abort(
        .internalServerError,
        reason: "Unexpected nil constructing signed upload url"
      )
    }

    let signedUrl = try Current.aws.signedS3UploadUrl(objectName)

    try await Current.db.create(Screenshot(
      userDeviceId: userDevice.id,
      url: webUrlString,
      width: input.width,
      height: input.height,
      filterSuspended: input.filterSuspended ?? false,
      createdAt: input.createdAt ?? Date()
    ))

    return .init(uploadUrl: signedUrl, webUrl: webUrl)
  }
}
